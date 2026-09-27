package com.openbag.modules.delivery.dto;

import com.openbag.enums.OrderStatus;
import com.openbag.enums.RouteOrigin;
import com.openbag.enums.RouteStatus;
import com.openbag.modules.delivery.dispatch.ReassignPolicy.CourierKind;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Painel de rotas da loja: o que está montando (sem entregador) e o que está com entregador.
 * Um pedido sozinho aparece como um cartão de uma parada ({@code routeId} nulo).
 */
public record RoutesBoardDTO(RouteSettingsDTO settings, Double storeLatitude, Double storeLongitude,
                             List<RouteCard> planning, List<RouteCard> active) {

    /**
     * @param dispatchAt quando o entregador será chamado (ainda montando)
     * @param waitReason aviso de espera, ex.: "Aguardando #0012 ficar pronto (~4 min) para sair junto"
     */
    public record RouteCard(Long routeId, RouteStatus status, RouteOrigin origin, String courierName,
                            CourierKind courierKind, Double totalDistanceKm, Double savedDistanceKm,
                            LocalDateTime dispatchAt, String waitReason, LocalDateTime searchingCourierSince,
                            List<Stop> stops) {
    }

    public record Stop(Long orderId, String displayCode, OrderStatus status, String neighborhood, String address,
                       Double latitude, Double longitude, LocalDateTime readyAt, LocalDateTime expectedReadyAt,
                       LocalDateTime pickedUpAt, boolean solo) {
    }
}
