package com.openbag.order.core.dto;

import com.openbag.platform.geo.GeocodingService;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * Taxa de entrega para o endereço do checkout, antes de fazer o pedido
 */
public record DeliveryQuoteRequest(
        @NotNull(message = "Informe a loja") Long restaurantId,
        @Size(max = 200) String street,
        @Size(max = 20) String number,
        @Size(max = 100) String neighborhood,
        @Size(max = 100) String city,
        @Size(max = 2) String state,
        @Size(max = 10) String zipCode,
        Double latitude,
        Double longitude) {

    public GeocodingService.AddressQuery toQuery() {
        return new GeocodingService.AddressQuery(street, number, neighborhood, city, state, zipCode);
    }
}
