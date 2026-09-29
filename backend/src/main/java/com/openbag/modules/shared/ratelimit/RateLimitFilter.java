package com.openbag.modules.shared.ratelimit;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.openbag.modules.shared.web.CachedBodyRequest;
import com.openbag.security.CustomUserDetailsService.CustomUserPrincipal;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.util.AntPathMatcher;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.util.UrlPathHelper;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * Limite de requisições (rate limiting) nas rotas que mais atraem abuso: login, cadastros, consulta de email,
 * cotação de entrega, pedidos e envio de arquivos. Passou do limite, a resposta é 429 com {@code Retry-After}.
 *
 * <p>Rotas sem login contam por IP; rotas com login, por usuário. O login conta também por email, para proteger
 * a conta de tentativas vindas de vários IPs. Os limites vêm de {@code app.rate-limit.limits.*} (ver
 * {@link #DEFAULTS}). O IP é o do socket: atrás de um proxy confiável, ligue {@code server.forward-headers-strategy}.
 *
 * <p>Fica na cadeia do Spring Security, depois do filtro do JWT (para saber o usuário) e antes da idempotência.
 */
@Component
@Slf4j
public class RateLimitFilter extends OncePerRequestFilter {

    /** Limites padrão; cada um pode ser trocado por {@code app.rate-limit.limits.<nome>} */
    static final Map<String, String> DEFAULTS = Map.of(
            "login-ip", "10/1m",
            "login-ip-hourly", "50/1h",
            "login-email", "10/15m",
            "register-ip", "10/1h",
            "check-email-ip", "20/1m",
            "public-quote-ip", "30/1m",
            "order-user", "10/1m",
            "store-order-user", "30/1m",
            "quote-user", "30/1m",
            "upload-user", "30/1h");

    private static final AntPathMatcher PATHS = new AntPathMatcher();
    private static final UrlPathHelper URLS = new UrlPathHelper();

    private final RateLimiter limiter;
    private final ObjectMapper objectMapper;
    private final boolean enabled;
    private final Map<String, RateLimit> limits = new HashMap<>();

    public RateLimitFilter(RateLimiter limiter, ObjectMapper objectMapper, RateLimitProperties properties,
                           @Value("${app.rate-limit.enabled:true}") boolean enabled) {
        this.limiter = limiter;
        this.objectMapper = objectMapper;
        this.enabled = enabled;
        DEFAULTS.forEach((name, value) -> limits.put(name, RateLimit.parse(properties.getLimits().getOrDefault(name, value))));
        properties.getLimits().keySet().stream().filter(name -> !DEFAULTS.containsKey(name)).forEach(name ->
                log.warn("Limite de requisições desconhecido em app.rate-limit.limits: {}", name));
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !enabled || "OPTIONS".equals(request.getMethod());
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String method = request.getMethod();
        String path = URLS.getPathWithinApplication(request);
        String ip = request.getRemoteAddr();
        Long userId = currentUserId();
        List<String> buckets = new ArrayList<>();
        HttpServletRequest forward = request;

        if ("POST".equals(method) && "/auth/login".equals(path)) {
            buckets.add("login-ip:" + ip);
            buckets.add("login-ip-hourly:" + ip);
            CachedBodyRequest cached = CachedBodyRequest.of(request);
            forward = cached;
            String email = loginEmail(cached.getBody());
            if (email != null) {
                buckets.add("login-email:" + email);
            }
        } else if ("POST".equals(method) && (path.equals("/auth/register") || PATHS.match("/auth/register/**", path))) {
            buckets.add("register-ip:" + ip);
        } else if ("GET".equals(method) && "/auth/check-email".equals(path)) {
            buckets.add("check-email-ip:" + ip);
        } else if ("GET".equals(method) && PATHS.match("/public/restaurants/*/delivery-quote", path)) {
            buckets.add("public-quote-ip:" + ip);
        } else if (userId != null && "POST".equals(method)) {
            if ("/orders".equals(path)) {
                buckets.add("order-user:" + userId);
            } else if ("/orders/delivery-quote".equals(path)) {
                buckets.add("quote-user:" + userId);
            } else if (PATHS.match("/restaurants/*/orders", path)) {
                buckets.add("store-order-user:" + userId);
            }
        }
        if (userId != null && isMultipart(request)) {
            buckets.add("upload-user:" + userId);
        }

        for (String bucket : buckets) {
            RateLimit limit = limits.get(bucket.substring(0, bucket.indexOf(':')));
            RateLimiter.Decision decision = limiter.tryConsume(bucket, limit);
            if (!decision.allowed()) {
                tooManyRequests(response, bucket, decision.retryAfterSeconds());
                return;
            }
        }
        chain.doFilter(forward, response);
    }

    private void tooManyRequests(HttpServletResponse response, String bucket, long retryAfter) throws IOException {
        // Sem o valor da chave no log (IP, email ou usuário): só o tipo de limite
        log.info("Limite de requisições atingido: {} (tente em {} s)", bucket.substring(0, bucket.indexOf(':')), retryAfter);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("status", HttpStatus.TOO_MANY_REQUESTS.value());
        body.put("message", "Muitas tentativas em pouco tempo. Tente de novo em " + waitText(retryAfter) + ".");
        body.put("timestamp", LocalDateTime.now().toString());
        response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
        response.setHeader("Retry-After", String.valueOf(retryAfter));
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding(StandardCharsets.UTF_8.name());
        response.getWriter().write(objectMapper.writeValueAsString(body));
    }

    static String waitText(long seconds) {
        if (seconds < 60) {
            return seconds + (seconds == 1 ? " segundo" : " segundos");
        }
        long minutes = (seconds + 59) / 60;
        return minutes + (minutes == 1 ? " minuto" : " minutos");
    }

    private String loginEmail(byte[] body) {
        try {
            JsonNode email = objectMapper.readTree(body).path("email");
            return email.isTextual() && !email.asText().isBlank() ? email.asText().trim().toLowerCase(Locale.ROOT) : null;
        } catch (IOException e) {
            return null;
        }
    }

    private static boolean isMultipart(HttpServletRequest request) {
        String contentType = request.getContentType();
        return contentType != null && contentType.startsWith(MediaType.MULTIPART_FORM_DATA_VALUE);
    }

    private static Long currentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof CustomUserPrincipal principal) {
            return principal.getId();
        }
        return null;
    }
}
