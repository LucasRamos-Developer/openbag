package com.openbag.modules.order.realtime;

import java.time.LocalDateTime;

/**
 * Nova posição do entregador para o cliente do pedido que está na vez. Enviada depois do commit.
 */
public record CourierLocationEvent(Long orderId, double latitude, double longitude, LocalDateTime at) {
}
