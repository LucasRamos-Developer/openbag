package com.openbag.restaurant.store.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PauseRequest {

    @NotNull(message = "Informe por quantos minutos pausar")
    @Min(value = 5, message = "Pausa mínima de 5 minutos")
    @Max(value = 240, message = "Pausa máxima de 240 minutos")
    private Integer minutes;
}
