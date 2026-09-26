package com.openbag.modules.delivery.service;

import com.openbag.modules.organization.entity.DeliveryRate;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Valor da entrega pela tabela da associação e subsídio do restaurante quando a taxa cobrada do cliente é menor
 */
public final class DeliveryRateCalculator {

    private DeliveryRateCalculator() {
    }

    /**
     * {@code baseFee + max(0, distância − baseDistanceKm) × extraPerKm}. Sem distância conhecida, só o valor base.
     */
    public static BigDecimal courierFee(DeliveryRate rate, Double distanceKm) {
        if (rate == null || !rate.isConfigured()) {
            throw new IllegalArgumentException("Tabela de entrega não configurada");
        }
        BigDecimal fee = rate.getBaseFee();
        if (distanceKm != null && rate.getExtraPerKm() != null && rate.getExtraPerKm().signum() > 0) {
            BigDecimal extraKm = BigDecimal.valueOf(distanceKm).subtract(rate.getBaseDistanceKm());
            if (extraKm.signum() > 0) {
                fee = fee.add(extraKm.multiply(rate.getExtraPerKm()));
            }
        }
        return fee.setScale(2, RoundingMode.HALF_UP);
    }

    /**
     * Quanto o restaurante assume: a diferença entre o valor do entregador e a taxa cobrada do cliente (nunca negativa)
     */
    public static BigDecimal subsidy(BigDecimal courierFee, BigDecimal customerFee) {
        BigDecimal charged = customerFee != null ? customerFee : BigDecimal.ZERO;
        return courierFee.subtract(charged).max(BigDecimal.ZERO).setScale(2, RoundingMode.HALF_UP);
    }
}
