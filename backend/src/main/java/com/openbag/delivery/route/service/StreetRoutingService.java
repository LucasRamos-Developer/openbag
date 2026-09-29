package com.openbag.delivery.route.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.openbag.delivery.route.dto.RoutesBoardDTO;
import com.openbag.delivery.route.repository.DeliveryRouteRepository;
import com.openbag.delivery.route.repository.DeliveryRouteRepository.StreetPath;
import lombok.extern.slf4j.Slf4j;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.LineString;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.function.Function;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * Caminho pelas ruas entre a loja e as paradas, para desenhar a rota no mapa. Usa um servidor OSRM
 * (app.routing.osrm-url). O caminho de uma rota fica salvo nela ({@code delivery_routes.street_path},
 * PostGIS) junto com as paradas usadas no cálculo, e só é refeito quando as paradas mudam; o de um
 * pedido sozinho fica só em memória. Sem resposta, o mapa volta à linha reta.
 *
 * O padrão é o servidor público de demonstração do OSRM, que serve para desenvolvimento (no máximo
 * 1 consulta por segundo). Em produção, use um OSRM próprio (OPENBAG_OSRM_URL).
 */
@Service
@Slf4j
public class StreetRoutingService {

    private static final int CACHE_SIZE = 500;
    private static final Duration TIMEOUT = Duration.ofSeconds(3);
    /** Depois de uma falha, espera antes de tentar de novo (não insiste com o servidor fora do ar) */
    private static final Duration RETRY_AFTER_FAILURE = Duration.ofMinutes(1);
    private static final GeometryFactory GEOMETRY = new GeometryFactory(new PrecisionModel(), 4326);

    private final ObjectMapper objectMapper;
    private final DeliveryRouteRepository routeRepository;
    private final HttpClient httpClient;
    private final String baseUrl;
    private final boolean enabled;

    private final Map<String, List<double[]>> cache = new LinkedHashMap<>(16, 0.75f, true) {
        @Override
        protected boolean removeEldestEntry(Map.Entry<String, List<double[]>> eldest) {
            return size() > CACHE_SIZE;
        }
    };
    private volatile Instant pausedUntil = Instant.MIN;

    public StreetRoutingService(ObjectMapper objectMapper, DeliveryRouteRepository routeRepository,
                                @Value("${app.routing.osrm-url:https://router.project-osrm.org}") String baseUrl,
                                @Value("${app.routing.enabled:true}") boolean enabled) {
        this.objectMapper = objectMapper;
        this.routeRepository = routeRepository;
        this.baseUrl = baseUrl.replaceAll("/+$", "");
        this.enabled = enabled;
        this.httpClient = HttpClient.newBuilder().connectTimeout(TIMEOUT).build();
    }

    /** O painel com o caminho pelas ruas de cada cartão (loja → paradas na ordem) */
    public RoutesBoardDTO withStreetPaths(RoutesBoardDTO board) {
        if (!enabled || board.storeLatitude() == null || board.storeLongitude() == null) {
            return board;
        }
        double[] store = {board.storeLatitude(), board.storeLongitude()};
        Map<Long, StreetPath> saved = savedPaths(board);
        return new RoutesBoardDTO(board.settings(), board.storeLatitude(), board.storeLongitude(),
                board.planning().stream().map(card -> withPath(card, store, saved)).toList(),
                board.active().stream().map(card -> withPath(card, store, saved)).toList());
    }

    /** Caminhos já salvos das rotas do painel, numa consulta só */
    private Map<Long, StreetPath> savedPaths(RoutesBoardDTO board) {
        List<Long> routeIds = Stream.concat(board.planning().stream(), board.active().stream())
                .map(RoutesBoardDTO.RouteCard::routeId)
                .filter(Objects::nonNull)
                .toList();
        if (routeIds.isEmpty()) {
            return Map.of();
        }
        return routeRepository.findStreetPaths(routeIds).stream()
                .collect(Collectors.toMap(StreetPath::getId, Function.identity()));
    }

    private RoutesBoardDTO.RouteCard withPath(RoutesBoardDTO.RouteCard card, double[] store,
                                              Map<Long, StreetPath> saved) {
        List<double[]> points = new ArrayList<>();
        points.add(store);
        card.stops().stream()
                .filter(s -> s.latitude() != null && s.longitude() != null)
                .forEach(s -> points.add(new double[]{s.latitude(), s.longitude()}));
        if (points.size() < 2) {
            return card.withPath(null);
        }
        String key = key(points);
        StreetPath stored = card.routeId() == null ? null : saved.get(card.routeId());
        if (stored != null && key.equals(stored.getStreetPathKey())) {
            return card.withPath(toLatLng(stored.getStreetPath()));
        }
        List<double[]> path = path(points).orElse(null);
        if (path != null && path.size() >= 2 && card.routeId() != null) {
            save(card.routeId(), key, path);
        }
        return card.withPath(path);
    }

    /** Salvar o caminho é só para não refazer a consulta: se falhar, o painel segue com o que já tem */
    private void save(Long routeId, String key, List<double[]> path) {
        try {
            routeRepository.saveStreetPath(routeId, key, toLineString(path));
        } catch (RuntimeException e) {
            log.warn("Caminho da rota {} não foi salvo: {}", routeId, e.getMessage());
        }
    }

    /** Caminho pelas ruas passando pelos pontos na ordem ([lat, lng]); vazio se o roteamento falhar */
    public Optional<List<double[]>> path(List<double[]> points) {
        String key = key(points);
        synchronized (cache) {
            List<double[]> cached = cache.get(key);
            if (cached != null) {
                return Optional.of(cached);
            }
        }
        if (Instant.now().isBefore(pausedUntil)) {
            return Optional.empty();
        }
        try {
            HttpRequest request = HttpRequest.newBuilder(
                            URI.create(baseUrl + "/route/v1/driving/" + key + "?overview=full&geometries=geojson"))
                    .timeout(TIMEOUT)
                    .header("User-Agent", "OpenBag (https://github.com/LucasRamos-Developer/openbag)")
                    .GET()
                    .build();
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            List<double[]> path = parse(response.body());
            if (response.statusCode() != 200 || path.isEmpty()) {
                throw new IllegalStateException("resposta " + response.statusCode());
            }
            synchronized (cache) {
                cache.put(key, path);
            }
            return Optional.of(path);
        } catch (Exception e) {
            if (e instanceof InterruptedException) {
                Thread.currentThread().interrupt();
            }
            pausedUntil = Instant.now().plus(RETRY_AFTER_FAILURE);
            log.warn("Roteamento indisponível ({}): o mapa usa linha reta por {} s", e.getMessage(),
                    RETRY_AFTER_FAILURE.toSeconds());
            return Optional.empty();
        }
    }

    /** Os pontos no formato do OSRM ("lng,lat;lng,lat"), com 5 casas (~1 m): identifica as paradas do caminho */
    static String key(List<double[]> points) {
        return points.stream()
                .map(p -> String.format(Locale.ROOT, "%.5f,%.5f", p[1], p[0]))
                .collect(Collectors.joining(";"));
    }

    /** Lista de [lat, lng] para a geometria do PostGIS (x = lng, y = lat) */
    static LineString toLineString(List<double[]> path) {
        return GEOMETRY.createLineString(path.stream().map(p -> new Coordinate(p[1], p[0])).toArray(Coordinate[]::new));
    }

    /** Geometria do PostGIS para a lista de [lat, lng] */
    static List<double[]> toLatLng(LineString line) {
        return Arrays.stream(line.getCoordinates()).map(c -> new double[]{c.getY(), c.getX()}).toList();
    }

    /** GeoJSON do OSRM ([lng, lat]) para a lista de [lat, lng] */
    List<double[]> parse(String body) throws java.io.IOException {
        JsonNode coordinates = objectMapper.readTree(body).path("routes").path(0).path("geometry").path("coordinates");
        List<double[]> path = new ArrayList<>();
        for (JsonNode c : coordinates) {
            path.add(new double[]{c.get(1).asDouble(), c.get(0).asDouble()});
        }
        return path;
    }
}
