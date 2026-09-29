package com.openbag.association.core.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Tabela de valores de entrega definida pela associação: valor base até {@code baseDistanceKm} e, acima disso,
 * {@code extraPerKm} por km adicional (zero = sem adicional). O entregador recebe 100% do valor calculado.
 */
@Embeddable
@Data
@NoArgsConstructor
@AllArgsConstructor
public class DeliveryRate {

    @Column(name = "rate_base_fee", precision = 10, scale = 2)
    private BigDecimal baseFee;

    @Column(name = "rate_base_distance_km", precision = 5, scale = 2)
    private BigDecimal baseDistanceKm;

    @Column(name = "rate_extra_per_km", precision = 10, scale = 2)
    private BigDecimal extraPerKm;

    public boolean isConfigured() {
        return baseFee != null && baseDistanceKm != null;
    }
}
