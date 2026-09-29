package com.openbag.restaurant.store.dto;

import com.openbag.enums.AcceptanceMode;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class StoreSettingsRequest {

    @NotNull(message = "Modo de aceite é obrigatório")
    private AcceptanceMode acceptanceMode;

    @NotNull(message = "Prazo de aceite é obrigatório")
    @Min(value = 2, message = "Prazo mínimo de 2 minutos")
    @Max(value = 30, message = "Prazo máximo de 30 minutos")
    private Integer acceptanceTimeoutMinutes;

    @NotNull(message = "Tempo de preparo é obrigatório")
    @Min(value = 1, message = "Tempo de preparo mínimo de 1 minuto")
    @Max(value = 240, message = "Tempo de preparo máximo de 240 minutos")
    private Integer defaultPreparationMinutes;

    @NotNull(message = "Taxa de entrega é obrigatória")
    @DecimalMin(value = "0.00", message = "Taxa de entrega não pode ser negativa")
    private BigDecimal deliveryFee;

    @NotNull(message = "Pedido mínimo é obrigatório")
    @DecimalMin(value = "0.00", message = "Pedido mínimo não pode ser negativo")
    private BigDecimal minimumOrder;

    @NotNull(message = "Tempo mínimo de entrega é obrigatório")
    @Min(value = 1, message = "Tempo mínimo de entrega deve ser positivo")
    private Integer deliveryTimeMin;

    @NotNull(message = "Tempo máximo de entrega é obrigatório")
    @Min(value = 1, message = "Tempo máximo de entrega deve ser positivo")
    private Integer deliveryTimeMax;

    private boolean autoPrintTicket;
}
