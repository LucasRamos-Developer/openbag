package com.openbag.delivery.dispatch.service;

import com.openbag.association.core.entity.DeliveryRate;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class DeliveryRateCalculatorTest {

    private static final DeliveryRate RATE = new DeliveryRate(new BigDecimal("7.00"), new BigDecimal("3.0"), new BigDecimal("1.50"));

    @Test
    void baseFeeCoversUpToBaseDistance() {
        assertThat(DeliveryRateCalculator.courierFee(RATE, 2.4)).isEqualByComparingTo("7.00");
        assertThat(DeliveryRateCalculator.courierFee(RATE, 3.0)).isEqualByComparingTo("7.00");
    }

    @Test
    void extraPerKmAboveBaseDistance() {
        // 7,00 + 2,5 km × 1,50 = 10,75
        assertThat(DeliveryRateCalculator.courierFee(RATE, 5.5)).isEqualByComparingTo("10.75");
    }

    @Test
    void zeroExtraMeansNoAdditional() {
        DeliveryRate flat = new DeliveryRate(new BigDecimal("8.00"), new BigDecimal("3.0"), BigDecimal.ZERO);
        assertThat(DeliveryRateCalculator.courierFee(flat, 12.0)).isEqualByComparingTo("8.00");
    }

    @Test
    void unknownDistanceChargesBaseOnly() {
        assertThat(DeliveryRateCalculator.courierFee(RATE, null)).isEqualByComparingTo("7.00");
    }

    @Test
    void notConfiguredFails() {
        assertThatThrownBy(() -> DeliveryRateCalculator.courierFee(new DeliveryRate(), 1.0))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void subsidyIsTheDifferenceNeverNegative() {
        assertThat(DeliveryRateCalculator.subsidy(new BigDecimal("10.75"), new BigDecimal("6.00"))).isEqualByComparingTo("4.75");
        assertThat(DeliveryRateCalculator.subsidy(new BigDecimal("7.00"), new BigDecimal("9.00"))).isEqualByComparingTo("0.00");
        assertThat(DeliveryRateCalculator.subsidy(new BigDecimal("7.00"), null)).isEqualByComparingTo("7.00");
    }
}
