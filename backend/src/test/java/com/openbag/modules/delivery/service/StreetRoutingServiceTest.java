package com.openbag.modules.delivery.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.openbag.modules.delivery.dto.RoutesBoardDTO;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class StreetRoutingServiceTest {

    private static final String OSRM_RESPONSE = """
            {"code":"Ok","routes":[{"geometry":{"type":"LineString",
              "coordinates":[[-49.0661,-26.9194],[-49.0700,-26.9190],[-49.0935,-26.9185]]}}]}
            """;

    private static RoutesBoardDTO.RouteCard card() {
        RoutesBoardDTO.Stop stop = new RoutesBoardDTO.Stop(1L, "#0001", null, "Velha", "Rua A, 1",
                -26.9185, -49.0935, null, null, null, false);
        return new RoutesBoardDTO.RouteCard(null, null, null, null, null, null, null, null, null, null, List.of(stop));
    }

    @Test
    void readsGeoJsonAsLatLng() throws Exception {
        StreetRoutingService service = new StreetRoutingService(new ObjectMapper(), "http://localhost", true);

        List<double[]> path = service.parse(OSRM_RESPONSE);

        assertThat(path).hasSize(3);
        assertThat(path.get(0)).containsExactly(-26.9194, -49.0661);
        assertThat(path.get(2)).containsExactly(-26.9185, -49.0935);
    }

    @Test
    void unreachableRouterKeepsStraightLine() {
        // Porta fechada: falha na hora e o cartão fica sem caminho (o mapa desenha a linha reta)
        StreetRoutingService service = new StreetRoutingService(new ObjectMapper(), "http://127.0.0.1:9", true);
        RoutesBoardDTO board = new RoutesBoardDTO(null, -26.9194, -49.0661, List.of(card()), List.of());

        RoutesBoardDTO result = service.withStreetPaths(board);

        assertThat(result.planning().get(0).path()).isNull();
        assertThat(result.planning().get(0).stops()).hasSize(1);
    }

    @Test
    void disabledRoutingLeavesBoardUntouched() {
        StreetRoutingService service = new StreetRoutingService(new ObjectMapper(), "http://127.0.0.1:9", false);
        RoutesBoardDTO board = new RoutesBoardDTO(null, -26.9194, -49.0661, List.of(card()), List.of());

        assertThat(service.withStreetPaths(board)).isSameAs(board);
    }
}
