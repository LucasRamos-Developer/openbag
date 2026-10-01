package com.openbag.delivery.courier.dto;

/**
 * "Entreguei": o PIN que o cliente mostrou (quando a loja exige) e onde o entregador está. Tudo opcional; sem
 * posição, vale a última recebida.
 */
public record DeliverRequest(String pin, Double latitude, Double longitude) {
}
