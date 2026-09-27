package com.openbag.modules.delivery.dto;

import com.openbag.enums.VehicleType;
import com.openbag.modules.delivery.dispatch.ReassignPolicy.CourierKind;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Quem pode levar um pedido agora e se a loja pode trocar quem está com ele
 *
 * @param current quem está com o pedido (nulo se ninguém) e se a troca está liberada
 */
public record CourierOptionsDTO(Current current, List<Option> options) {

    public record Current(CourierKind kind, String name, boolean canReassign, String reason,
                          LocalDateTime availableAt, boolean atStore) {
    }

    /**
     * @param distanceKm distância até a loja (entregadores do app com localização)
     * @param fee        quanto ele recebe por esta entrega
     * @param blockedReason motivo de não poder receber agora; nulo = pode
     */
    public record Option(CourierKind kind, Long deliveryPersonId, Long staffCourierId, String name, String photoUrl,
                         VehicleType vehicleType, Double distanceKm, BigDecimal fee, String blockedReason) {
    }
}
