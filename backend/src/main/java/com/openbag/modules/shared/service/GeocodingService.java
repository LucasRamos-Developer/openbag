package com.openbag.modules.shared.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicReference;
import java.util.stream.Collectors;

/**
 * Coordenadas de um endereço de entrega, para medir a distância até a loja (taxa por km e despacho).
 *
 * Usa a busca estruturada do Nominatim (OpenStreetMap), com o padrão no servidor público, que aceita no máximo
 * 1 consulta por segundo: o serviço respeita esse intervalo, guarda as respostas em memória e, depois de uma
 * falha, espera um pouco antes de tentar de novo. Em produção, use um Nominatim próprio (OPENBAG_GEOCODING_URL).
 * Sem resposta, o endereço fica sem coordenadas e a taxa por distância usa o valor "a partir de".
 */
@Service
@Slf4j
public class GeocodingService {

    private static final int CACHE_SIZE = 1000;
    private static final Duration TIMEOUT = Duration.ofSeconds(4);
    private static final Duration MIN_INTERVAL = Duration.ofMillis(1100);
    private static final Duration RETRY_AFTER_FAILURE = Duration.ofMinutes(1);
    /** Espera máxima por uma vaga na fila de 1 consulta por segundo; passou disso, o endereço fica sem coordenadas */
    private static final Duration MAX_WAIT = Duration.ofSeconds(3);

    /** Endereço para buscar; os campos vazios são ignorados */
    public record AddressQuery(String street, String number, String neighborhood, String city, String state,
                               String zipCode) {
    }

    public record Coordinates(double latitude, double longitude) {
    }

    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;
    private final String baseUrl;
    private final boolean enabled;

    private final Map<String, Optional<Coordinates>> cache = new LinkedHashMap<>(16, 0.75f, true) {
        @Override
        protected boolean removeEldestEntry(Map.Entry<String, Optional<Coordinates>> eldest) {
            return size() > CACHE_SIZE;
        }
    };
    /** Próxima vaga livre na fila de 1 consulta por segundo */
    private final AtomicReference<Instant> nextSlot = new AtomicReference<>(Instant.MIN);
    private volatile Instant pausedUntil = Instant.MIN;

    public GeocodingService(ObjectMapper objectMapper,
                            @Value("${app.geocoding.url:https://nominatim.openstreetmap.org}") String baseUrl,
                            @Value("${app.geocoding.enabled:true}") boolean enabled) {
        this.objectMapper = objectMapper;
        this.baseUrl = baseUrl.replaceAll("/+$", "");
        this.enabled = enabled;
        this.httpClient = HttpClient.newBuilder().connectTimeout(TIMEOUT).build();
    }

    /**
     * Procura primeiro com rua e número; se não achar, só pela rua (o número nem sempre está no mapa)
     */
    public Optional<Coordinates> locate(AddressQuery address) {
        if (!enabled || address == null || isBlank(address.street()) || isBlank(address.city())) {
            return Optional.empty();
        }
        String street = isBlank(address.number()) ? address.street().trim()
                : address.number().trim() + " " + address.street().trim();
        Optional<Coordinates> found = search(street, address);
        if (found.isEmpty() && !isBlank(address.number())) {
            found = search(address.street().trim(), address);
        }
        return found;
    }

    private Optional<Coordinates> search(String street, AddressQuery address) {
        Map<String, String> params = new LinkedHashMap<>();
        params.put("format", "json");
        params.put("limit", "1");
        params.put("countrycodes", "br");
        params.put("street", street);
        params.put("city", address.city().trim());
        // Sem o CEP: poucos CEPs estão no mapa e ele faria a busca falhar à toa
        if (!isBlank(address.state())) params.put("state", address.state().trim());

        String query = params.entrySet().stream()
                .map(e -> e.getKey() + "=" + URLEncoder.encode(e.getValue(), StandardCharsets.UTF_8))
                .collect(Collectors.joining("&"));
        String key = query.toLowerCase(Locale.ROOT);
        synchronized (cache) {
            if (cache.containsKey(key)) {
                return cache.get(key);
            }
        }
        if (Instant.now().isBefore(pausedUntil)) {
            return Optional.empty();
        }

        try {
            if (!waitForTurn()) {
                log.info("Geocodificação: fila cheia; o endereço fica sem coordenadas (vale o valor \"a partir de\")");
                return Optional.empty();
            }
            HttpRequest request = HttpRequest.newBuilder(URI.create(baseUrl + "/search?" + query))
                    .timeout(TIMEOUT)
                    .header("User-Agent", "OpenBag (https://github.com/LucasRamos-Developer/openbag)")
                    .header("Accept-Language", "pt-BR")
                    .GET()
                    .build();
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() != 200) {
                throw new IllegalStateException("resposta " + response.statusCode());
            }
            Optional<Coordinates> result = parse(response.body());
            synchronized (cache) {
                cache.put(key, result);
            }
            return result;
        } catch (Exception e) {
            if (e instanceof InterruptedException) {
                Thread.currentThread().interrupt();
            }
            pausedUntil = Instant.now().plus(RETRY_AFTER_FAILURE);
            log.warn("Geocodificação indisponível ({}): endereços ficam sem coordenadas por {} s", e.getMessage(),
                    RETRY_AFTER_FAILURE.toSeconds());
            return Optional.empty();
        }
    }

    /**
     * O servidor público aceita 1 consulta por segundo: reserva a próxima vaga e espera por ela. Se a vaga estiver a
     * mais de {@link #MAX_WAIT}, desiste na hora. Antes, cada requisição esperava a vez com a thread presa, e uma
     * enxurrada de endereços diferentes esgotava as threads do servidor.
     */
    boolean waitForTurn() throws InterruptedException {
        Instant now = Instant.now();
        Instant slot;
        while (true) {
            Instant current = nextSlot.get();
            slot = current.isAfter(now) ? current : now;
            if (Duration.between(now, slot).compareTo(MAX_WAIT) > 0) {
                return false;
            }
            if (nextSlot.compareAndSet(current, slot.plus(MIN_INTERVAL))) {
                break;
            }
        }
        long wait = Duration.between(now, slot).toMillis();
        if (wait > 0) {
            Thread.sleep(wait);
        }
        return true;
    }

    Optional<Coordinates> parse(String body) throws java.io.IOException {
        JsonNode first = objectMapper.readTree(body).path(0);
        if (first.isMissingNode() || !first.hasNonNull("lat") || !first.hasNonNull("lon")) {
            return Optional.empty();
        }
        return Optional.of(new Coordinates(first.get("lat").asDouble(), first.get("lon").asDouble()));
    }

    private static boolean isBlank(String value) {
        return value == null || value.isBlank();
    }
}
