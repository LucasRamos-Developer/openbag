package com.openbag.delivery.dispatch.service;

import com.openbag.delivery.dispatch.service.CourierSelector.Candidate;
import com.openbag.delivery.courier.entity.DeliveryPerson;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class CourierSelectorTest {

    private static final double RADIUS = 6.0;

    private static DeliveryPerson courier(long id) {
        DeliveryPerson dp = new DeliveryPerson();
        dp.setId(id);
        return dp;
    }

    private static Candidate free(long id, double km, String earned) {
        return new Candidate(courier(id), km, new BigDecimal("7.00"), new BigDecimal(earned), 0, null, null);
    }

    private static Candidate fixed(long id, int deliveries, LocalDateTime lastDelivery, LocalDateTime start) {
        return new Candidate(courier(id), null, new BigDecimal("7.00"), null, deliveries, lastDelivery, start);
    }

    @Test
    void feeRuleRequiresCoverageWhenCourierFeeExceedsCustomerFee() {
        assertThat(CourierSelector.feeAllowed(new BigDecimal("8.00"), new BigDecimal("8.00"), false)).isTrue();
        assertThat(CourierSelector.feeAllowed(new BigDecimal("8.01"), new BigDecimal("8.00"), false)).isFalse();
        assertThat(CourierSelector.feeAllowed(new BigDecimal("12.00"), new BigDecimal("5.00"), true)).isTrue();
        assertThat(CourierSelector.feeAllowed(new BigDecimal("1.00"), null, false)).isFalse();
    }

    @Test
    void withSameEarningsTheClosestWins() {
        var choice = CourierSelector.pickFree(List.of(free(1, 4.0, "0"), free(2, 1.0, "0")), RADIUS, 0.5, 0.5);
        assertThat(choice).isPresent();
        assertThat(choice.get().candidate().courier().getId()).isEqualTo(2L);
    }

    @Test
    void fairnessFavorsWhoEarnedLessToday() {
        // O 1 está um pouco mais perto, mas já ganhou bem mais hoje
        var choice = CourierSelector.pickFree(List.of(free(1, 1.0, "120.00"), free(2, 2.0, "20.00")), RADIUS, 0.5, 0.5);
        assertThat(choice.get().candidate().courier().getId()).isEqualTo(2L);
    }

    @Test
    void distanceStillMattersWhenEarningsAreClose() {
        var choice = CourierSelector.pickFree(List.of(free(1, 5.5, "40.00"), free(2, 0.5, "42.00")), RADIUS, 0.5, 0.5);
        assertThat(choice.get().candidate().courier().getId()).isEqualTo(2L);
    }

    @Test
    void emptyPoolHasNoChoice() {
        assertThat(CourierSelector.pickFree(List.of(), RADIUS, 0.5, 0.5)).isEmpty();
        assertThat(CourierSelector.pickFixed(List.of())).isEmpty();
    }

    @Test
    void fixedRotationPicksFewestDeliveriesThenLongestIdle() {
        LocalDateTime now = LocalDateTime.of(2026, 9, 25, 12, 0);
        var fewer = CourierSelector.pickFixed(List.of(
                fixed(1, 3, now.minusMinutes(50), now.minusHours(3)),
                fixed(2, 1, now.minusMinutes(5), now.minusHours(1))));
        assertThat(fewer.get().candidate().courier().getId()).isEqualTo(2L);

        var idle = CourierSelector.pickFixed(List.of(
                fixed(1, 2, now.minusMinutes(5), now.minusHours(3)),
                fixed(2, 2, now.minusMinutes(40), now.minusHours(2)),
                fixed(3, 2, null, now.minusMinutes(10))));
        // Quem ainda não entregou no turno vem primeiro; depois quem entregou há mais tempo
        assertThat(idle.get().candidate().courier().getId()).isEqualTo(3L);
    }
}
