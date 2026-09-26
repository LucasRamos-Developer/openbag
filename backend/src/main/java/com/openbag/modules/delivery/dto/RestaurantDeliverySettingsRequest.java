package com.openbag.modules.delivery.dto;

import com.openbag.enums.CourierPolicy;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class RestaurantDeliverySettingsRequest {

    @NotNull(message = "Escolha quais entregadores recebem seus pedidos")
    private CourierPolicy courierPolicy;

    private boolean fallbackToOpen;

    private boolean coversDeliveryDifference;
}
