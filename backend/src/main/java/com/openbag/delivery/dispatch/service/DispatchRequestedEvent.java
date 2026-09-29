package com.openbag.delivery.dispatch.service;

/**
 * Pede uma nova rodada de oferta para o pedido (depois de uma recusa, por exemplo). Tratado após o commit.
 */
public record DispatchRequestedEvent(Long orderId) {
}
