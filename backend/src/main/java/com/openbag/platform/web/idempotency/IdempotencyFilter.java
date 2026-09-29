package com.openbag.platform.web.idempotency;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.openbag.platform.web.CachedBodyRequest;
import com.openbag.platform.security.CustomUserDetailsService.CustomUserPrincipal;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.util.ContentCachingResponseWrapper;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.regex.Pattern;

/**
 * Idempotência pelo cabeçalho {@code Idempotency-Key}: a mesma ação enviada de novo (toque duplo, nova tentativa
 * depois de um timeout) nunca é aplicada duas vezes.
 *
 * <ul>
 *   <li>Primeira vez: a chave é reservada, a ação roda e a resposta fica guardada.</li>
 *   <li>Mesma chave e mesmo corpo: devolve a resposta guardada, com {@code Idempotency-Replayed: true}.</li>
 *   <li>Mesma chave com outro corpo ou outra rota: 422.</li>
 *   <li>A primeira ainda está rodando: 409.</li>
 *   <li>Erro do servidor, conflito (409) ou limite de requisições (429): a chave é liberada para nova tentativa.</li>
 * </ul>
 *
 * Vale para qualquer POST, PUT, PATCH ou DELETE de um usuário logado que mande o cabeçalho; o app manda nas ações
 * que criam ou movem dinheiro (pedido, pedido do balcão, acerto de caixa, baixa de fatura, livro-caixa, aceite).
 * Fica na cadeia do Spring Security, depois do filtro do JWT, para saber quem é o usuário.
 */
@Component
@Slf4j
public class IdempotencyFilter extends OncePerRequestFilter {

    public static final String HEADER = "Idempotency-Key";
    public static final String REPLAYED_HEADER = "Idempotency-Replayed";

    private static final Set<String> METHODS = Set.of("POST", "PUT", "PATCH", "DELETE");
    private static final Pattern KEY = Pattern.compile("[A-Za-z0-9_-]{8,100}");
    private static final int MAX_BODY_BYTES = 1024 * 1024;

    /** Respostas que não ficam guardadas: a mesma ação pode dar certo numa nova tentativa */
    private static final Set<Integer> RETRYABLE = Set.of(HttpStatus.CONFLICT.value(), HttpStatus.TOO_MANY_REQUESTS.value());

    private final IdempotencyStore store;
    private final ObjectMapper objectMapper;

    public IdempotencyFilter(IdempotencyStore store, ObjectMapper objectMapper) {
        this.store = store;
        this.objectMapper = objectMapper;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return request.getHeader(HEADER) == null || !METHODS.contains(request.getMethod());
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        Long userId = currentUserId();
        String contentType = request.getContentType();
        if (userId == null || (contentType != null && contentType.startsWith(MediaType.MULTIPART_FORM_DATA_VALUE))
                || request.getContentLengthLong() > MAX_BODY_BYTES) {
            chain.doFilter(request, response);
            return;
        }
        String key = request.getHeader(HEADER).trim();
        if (!KEY.matcher(key).matches()) {
            error(response, HttpStatus.BAD_REQUEST, "Cabeçalho Idempotency-Key inválido (8 a 100 letras, números, - ou _)");
            return;
        }

        CachedBodyRequest cached = CachedBodyRequest.of(request);
        byte[] body = cached.getBody();
        String path = truncate(request.getRequestURI() + (request.getQueryString() != null ? "?" + request.getQueryString() : ""), 300);
        String hash = sha256(request.getMethod(), path, body);

        Optional<Long> reserved = store.reserve(userId, key, request.getMethod(), path, hash);
        if (reserved.isEmpty()) {
            Optional<IdempotencyStore.Entry> existing = store.find(userId, key);
            if (existing.isEmpty()) {
                // Apagada entre a tentativa e a consulta (liberada ou expirada): reserva de novo
                reserved = store.reserve(userId, key, request.getMethod(), path, hash);
            } else {
                IdempotencyStore.Entry entry = existing.get();
                if (!entry.requestHash().equals(hash)) {
                    error(response, HttpStatus.UNPROCESSABLE_ENTITY,
                            "Esta chave de idempotência já foi usada em outra ação");
                    return;
                }
                if (entry.completed()) {
                    replay(response, entry);
                    return;
                }
                if (!store.takeOverAbandoned(entry.id())) {
                    inProgress(response);
                    return;
                }
                reserved = Optional.of(entry.id());
            }
        }
        if (reserved.isEmpty()) {
            inProgress(response);
            return;
        }

        long id = reserved.get();
        ContentCachingResponseWrapper wrapped = new ContentCachingResponseWrapper(response);
        try {
            chain.doFilter(cached, wrapped);
        } catch (IOException | ServletException | RuntimeException e) {
            store.release(id);
            throw e;
        }
        int status = wrapped.getStatus();
        if (status >= 500 || RETRYABLE.contains(status)) {
            store.release(id);
        } else {
            store.complete(id, status, wrapped.getContentType(),
                    new String(wrapped.getContentAsByteArray(), StandardCharsets.UTF_8));
        }
        wrapped.copyBodyToResponse();
    }

    private void replay(HttpServletResponse response, IdempotencyStore.Entry entry) throws IOException {
        log.info("Idempotência: resposta repetida para {} {}", entry.method(), entry.path());
        response.setStatus(entry.responseStatus());
        response.setHeader(REPLAYED_HEADER, "true");
        if (entry.responseContentType() != null) {
            response.setContentType(entry.responseContentType());
        }
        if (entry.responseBody() != null && !entry.responseBody().isEmpty()) {
            response.setCharacterEncoding(StandardCharsets.UTF_8.name());
            response.getWriter().write(entry.responseBody());
        }
    }

    /** A primeira requisição ainda está rodando: o app espera e tenta de novo com a mesma chave */
    private void inProgress(HttpServletResponse response) throws IOException {
        response.setHeader("Retry-After", "2");
        error(response, HttpStatus.CONFLICT, "Esta ação ainda está sendo processada. Aguarde um instante.");
    }

    private void error(HttpServletResponse response, HttpStatus status, String message) throws IOException {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("status", status.value());
        body.put("message", message);
        body.put("timestamp", LocalDateTime.now().toString());
        response.setStatus(status.value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding(StandardCharsets.UTF_8.name());
        response.getWriter().write(objectMapper.writeValueAsString(body));
    }

    private static Long currentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof CustomUserPrincipal principal) {
            return principal.getId();
        }
        return null;
    }

    private static String sha256(String method, String path, byte[] body) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            digest.update((method + " " + path + "\n").getBytes(StandardCharsets.UTF_8));
            digest.update(body);
            return HexFormat.of().formatHex(digest.digest());
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }

    private static String truncate(String text, int max) {
        return text.length() <= max ? text : text.substring(0, max);
    }
}
