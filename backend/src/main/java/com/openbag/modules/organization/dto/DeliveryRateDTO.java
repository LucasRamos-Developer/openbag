package com.openbag.modules.organization.dto;

import com.openbag.modules.organization.entity.DeliveryRate;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Tabela de valores de entrega da associação (entrada e saída)
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class DeliveryRateDTO {

    @NotNull(message = "Valor base é obrigatório")
    @DecimalMin(value = "0.00", message = "Valor base não pode ser negativo")
    @DecimalMax(value = "999.99", message = "Valor base muito alto")
    private BigDecimal baseFee;

    @NotNull(message = "Distância coberta pelo valor base é obrigatória")
    @DecimalMin(value = "0.0", message = "Distância não pode ser negativa")
    @DecimalMax(value = "100.0", message = "Distância deve ser de no máximo 100 km")
    private BigDecimal baseDistanceKm;

    // Zero ou vazio = sem adicional por km
    @DecimalMin(value = "0.00", message = "Adicional por km não pode ser negativo")
    @DecimalMax(value = "99.99", message = "Adicional por km muito alto")
    private BigDecimal extraPerKm;

    private boolean configured;

    public static DeliveryRateDTO from(DeliveryRate rate) {
        if (rate == null || !rate.isConfigured()) {
            return new DeliveryRateDTO(null, null, null, false);
        }
        return new DeliveryRateDTO(rate.getBaseFee(), rate.getBaseDistanceKm(),
                rate.getExtraPerKm() != null ? rate.getExtraPerKm() : BigDecimal.ZERO, true);
    }

    public DeliveryRate toEntity() {
        return new DeliveryRate(baseFee, baseDistanceKm, extraPerKm != null ? extraPerKm : BigDecimal.ZERO);
    }
}
