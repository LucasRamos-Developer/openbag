package com.openbag.modules.delivery.dto;

import com.openbag.enums.CourierPolicy;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class RestaurantDeliverySettingsRequest {

    @NotNull(message = "Escolha quais entregadores recebem seus pedidos")
    private CourierPolicy courierPolicy;

    private boolean fallbackToOpen;

    private boolean coversDeliveryDifference;

    // Entregador livre que não aparece: minutos até a loja poder trocá-lo (nulo = mantém)
    @Min(value = 3, message = "Mínimo de 3 minutos")
    @Max(value = 60, message = "Máximo de 60 minutos")
    private Integer courierNoShowMinutes;
}
