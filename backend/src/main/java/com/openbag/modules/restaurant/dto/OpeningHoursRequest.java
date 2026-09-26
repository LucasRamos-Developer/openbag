package com.openbag.modules.restaurant.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Substitui todos os horários de funcionamento. Lista vazia = sem horário (vale só o abrir/fechar manual).
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class OpeningHoursRequest {

    @Valid
    @NotNull(message = "Informe os horários")
    private List<OpeningHourDTO> hours;
}
