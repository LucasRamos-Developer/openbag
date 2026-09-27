package com.openbag.modules.delivery.dto;

/**
 * Entregador a acertar: do app ou da equipe própria (um dos dois)
 */
public record SettleCourierRequest(Long deliveryPersonId, Long staffCourierId) {
}
