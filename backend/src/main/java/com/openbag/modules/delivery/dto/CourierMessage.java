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
        STATE_CHANGED
    }
}
