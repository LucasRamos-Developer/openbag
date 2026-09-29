package com.openbag.delivery.dispatch.dto;

import com.openbag.delivery.dispatch.service.DeliveryFeeQuoteService;

import java.math.BigDecimal;

/**
 * Taxa de entrega para um endereço. {@code byDistance} = a loja repassa a taxa e o valor depende da distância;
 * {@code distanceKm} nulo = o endereço não foi localizado no mapa (vale o valor "a partir de").
 */
public record DeliveryQuoteDTO(Double distanceKm, BigDecimal fee, boolean byDistance) {

    public static DeliveryQuoteDTO from(DeliveryFeeQuoteService.Quote quote) {
        return new DeliveryQuoteDTO(quote.distanceKm(), quote.fee(), quote.byDistance());
    }
}
