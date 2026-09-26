package com.openbag.modules.order.realtime;

/**
 * Pedido criado ou alterado. Publicado pelos services e enviado aos clientes depois do commit.
 */
public record OrderChangedEvent(Long orderId, Type type) {

    public enum Type {
        ORDER_CREATED,
        ORDER_UPDATED
    }
}
