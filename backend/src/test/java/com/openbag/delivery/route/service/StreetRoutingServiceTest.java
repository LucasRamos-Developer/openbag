package com.openbag.delivery.route.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.openbag.delivery.route.dto.RoutesBoardDTO;
import com.openbag.delivery.route.repository.DeliveryRouteRepository;
import com.openbag.delivery.route.repository.DeliveryRouteRepository.StreetPath;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.Test;
import org.locationtech.jts.geom.LineString;
import org.mockito.ArgumentCaptor;

import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

class StreetRoutingServiceTest {

    private static final String OSRM_RESPONSE = """
            {"code":"Ok","routes":[{"geometry":{"type":"LineString",
              "coordinates":[[-49.0661,-26.9194],[-49.0700,-26.9190],[-49.0935,-26.9185]]}}]}
            """;

    // Loja e parada do cartão, no formato da chave do caminho
    private static final String KEY = "-49.06610,-26.91940;-49.09350,-26.91850";

    private final DeliveryRouteRepository routeRepository = mock(DeliveryRouteRepository.class);

    private static RoutesBoardDTO.RouteCard card() {
        return card(null);
    }

    private static RoutesBoardDTO.RouteCard card(Long routeId) {
        RoutesBoardDTO.Stop stop = new RoutesBoardDTO.Stop(1L, "#0001", null, "Velha", "Rua A, 1",
                -26.9185, -49.0935, null, null, null, false);
        return new RoutesBoardDTO.RouteCard(routeId, null, null, null, null, null, null, null, null, null, List.of(stop));
    }

    private static RoutesBoardDTO board(RoutesBoardDTO.RouteCard card) {
        return new RoutesBoardDTO(null, -26.9194, -49.0661, List.of(card), List.of());
    }

    private static StreetPath saved(Long id, String key, List<double[]> path) {
        LineString line = StreetRoutingService.toLineString(path);
        return new StreetPath() {
            public Long getId() { return id; }
            public String getStreetPathKey() { return key; }
            public LineString getStreetPath() { return line; }
        };
    }

    /** OSRM de mentira numa porta livre, sempre com a mesma resposta */
    private static HttpServer fakeRouter() throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/", exchange -> {
            byte[] body = OSRM_RESPONSE.getBytes(StandardCharsets.UTF_8);
            exchange.sendResponseHeaders(200, body.length);
            exchange.getResponseBody().write(body);
            exchange.close();
        });
        server.start();
        return server;
    }

    @Test
    void readsGeoJsonAsLatLng() throws Exception {
        StreetRoutingService service = new StreetRoutingService(new ObjectMapper(), routeRepository, "http://localhost", true);

        List<double[]> path = service.parse(OSRM_RESPONSE);

        assertThat(path).hasSize(3);
        assertThat(path.get(0)).containsExactly(-26.9194, -49.0661);
        assertThat(path.get(2)).containsExactly(-26.9185, -49.0935);
    }

    @Test
    void unreachableRouterKeepsStraightLine() {
        // Porta fechada: falha na hora e o cartão fica sem caminho (o mapa desenha a linha reta)
        StreetRoutingService service = new StreetRoutingService(new ObjectMapper(), routeRepository, "http://127.0.0.1:9", true);

        RoutesBoardDTO result = service.withStreetPaths(board(card()));

        assertThat(result.planning().get(0).path()).isNull();
        assertThat(result.planning().get(0).stops()).hasSize(1);
        // Pedido sozinho não tem rota onde salvar
        verifyNoInteractions(routeRepository);
    }

    @Test
    void disabledRoutingLeavesBoardUntouched() {
        StreetRoutingService service = new StreetRoutingService(new ObjectMapper(), routeRepository, "http://127.0.0.1:9", false);
        RoutesBoardDTO board = new RoutesBoardDTO(null, -26.9194, -49.0661, List.of(card()), List.of());

        assertThat(service.withStreetPaths(board)).isSameAs(board);
    }

    @Test
    void geometryKeepsLatLngOrder() {
        List<double[]> path = List.of(new double[]{-26.9194, -49.0661}, new double[]{-26.9185, -49.0935});

        LineString line = StreetRoutingService.toLineString(path);

        assertThat(line.getSRID()).isEqualTo(4326);
        assertThat(line.getCoordinateN(0).getX()).isEqualTo(-49.0661);
        assertThat(line.getCoordinateN(0).getY()).isEqualTo(-26.9194);
        assertThat(StreetRoutingService.toLatLng(line)).containsExactly(path.get(0), path.get(1));
    }

    @Test
    void savedPathWithSameStopsSkipsRouter() {
        // Roteador fora do ar: se o caminho aparece, veio do banco
        StreetRoutingService service = new StreetRoutingService(new ObjectMapper(), routeRepository, "http://127.0.0.1:9", true);
        List<double[]> stored = List.of(new double[]{-26.9194, -49.0661}, new double[]{-26.9, -49.08},
                new double[]{-26.9185, -49.0935});
        when(routeRepository.findStreetPaths(List.of(7L))).thenReturn(List.of(saved(7L, KEY, stored)));

        RoutesBoardDTO result = service.withStreetPaths(board(card(7L)));

        assertThat(result.planning().get(0).path()).hasSize(3);
        assertThat(result.planning().get(0).path().get(1)).containsExactly(-26.9, -49.08);
        verify(routeRepository, never()).saveStreetPath(anyLong(), anyString(), any());
    }

    @Test
    void changedStopsRecomputeAndSavePath() throws Exception {
        HttpServer router = fakeRouter();
        try {
            StreetRoutingService service = new StreetRoutingService(new ObjectMapper(), routeRepository,
                    "http://127.0.0.1:" + router.getAddress().getPort(), true);
            List<double[]> old = List.of(new double[]{-26.9194, -49.0661}, new double[]{-26.8, -49.0});
            when(routeRepository.findStreetPaths(List.of(7L)))
                    .thenReturn(List.of(saved(7L, "-49.06610,-26.91940;-49.00000,-26.80000", old)));

            RoutesBoardDTO result = service.withStreetPaths(board(card(7L)));

            assertThat(result.planning().get(0).path()).hasSize(3);
            ArgumentCaptor<LineString> line = ArgumentCaptor.forClass(LineString.class);
            verify(routeRepository).saveStreetPath(eq(7L), eq(KEY), line.capture());
            assertThat(line.getValue().getNumPoints()).isEqualTo(3);
        } finally {
            router.stop(0);
        }
    }

    @Test
    void failedRoutingSavesNothing() {
        StreetRoutingService service = new StreetRoutingService(new ObjectMapper(), routeRepository, "http://127.0.0.1:9", true);
        when(routeRepository.findStreetPaths(List.of(7L))).thenReturn(List.of());

        RoutesBoardDTO result = service.withStreetPaths(board(card(7L)));

        assertThat(result.planning().get(0).path()).isNull();
        verify(routeRepository, never()).saveStreetPath(anyLong(), anyString(), any());
    }
}
