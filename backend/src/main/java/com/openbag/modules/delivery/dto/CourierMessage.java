package com.openbag.modules.delivery.dto;

/**
 * Mensagem do tópico do entregador (/topic/couriers/{id})
 */
public record CourierMessage(Type type, CourierOfferDTO offer, CourierOrderDTO order, String reason) {

    public enum Type {
        OFFER_CREATED,
        OFFER_CLOSED,
        ORDER_UPDATED,
        ORDER_CANCELLED,
        // A loja passou um pedido direto para o entregador / tirou o pedido dele
        ORDER_ASSIGNED,
        ORDER_UNASSIGNED,
        STATE_CHANGED
    }
}
