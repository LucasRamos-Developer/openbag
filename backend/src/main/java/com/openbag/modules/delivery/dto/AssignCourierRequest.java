package com.openbag.modules.delivery.dto;

/**
 * Quem vai levar o pedido: um entregador do app ou alguém da equipe própria (um dos dois)
 */
public record AssignCourierRequest(Long deliveryPersonId, Long staffCourierId) {
}
