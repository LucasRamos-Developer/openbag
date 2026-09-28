package com.openbag.modules.cooperative.dto;

import com.openbag.enums.AddonPricing;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

public record AddonPlanRequest(
        @NotBlank(message = "Dê um nome ao adicional") @Size(max = 80) String name,
        @Size(max = 500) String description,
        @NotNull(message = "Escolha como cobrar") AddonPricing pricing,
        @NotNull(message = "Informe o valor") @DecimalMin(value = "0.01", message = "O valor deve ser maior que zero")
        BigDecimal value,
        Boolean active) {
}
