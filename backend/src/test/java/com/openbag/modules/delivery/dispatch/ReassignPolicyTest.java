package com.openbag.modules.delivery.dispatch;

import com.openbag.enums.OrderStatus;
import com.openbag.enums.ShiftMode;
import com.openbag.modules.delivery.dispatch.ReassignPolicy.CourierKind;
import com.openbag.modules.delivery.dispatch.ReassignPolicy.Decision;
import com.openbag.modules.delivery.entity.CourierShift;
import com.openbag.modules.delivery.entity.DeliveryPerson;
import com.openbag.modules.delivery.entity.StaffCourier;
import com.openbag.order.core.entity.Order;
import com.openbag.restaurant.store.entity.Restaurant;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;

class ReassignPolicyTest {

    private static final LocalDateTime ASSIGNED = LocalDateTime.of(2026, 9, 27, 19, 0);
    private static final int STALE_S = 120;

    private Restaurant restaurant;
    private Order order;
    private DeliveryPerson courier;

    @BeforeEach
    void setUp() {
        restaurant = new Restaurant();
        restaurant.setId(1L);
        restaurant.setLatitude(new BigDecimal("-26.9194"));
        restaurant.setLongitude(new BigDecimal("-49.0661"));

        courier = new DeliveryPerson();
        courier.setId(5L);
        // Longe da loja (~2 km)
        courier.setLastLatitude(-26.9014);
        courier.setLastLongitude(-49.0661);

        order = new Order();
        order.setRestaurant(restaurant);
        order.setStatus(OrderStatus.PREPARING);
        order.setDeliveryPerson(courier);
        order.setAssignedAt(ASSIGNED);
    }

    private void shift(ShiftMode mode, Restaurant at) {
        CourierShift shift = new CourierShift();
        shift.setMode(mode);
        shift.setRestaurant(at);
        shift.setStartedAt(ASSIGNED.minusHours(1));
        courier.setCurrentShift(shift);
    }

    @Test
    void fixedCourierCanBeSwappedAnytime() {
        shift(ShiftMode.FIXED, restaurant);
        Decision decision = ReassignPolicy.decide(order, ASSIGNED.plusMinutes(1), STALE_S);

        assertThat(ReassignPolicy.kindOf(order)).isEqualTo(CourierKind.FIXED);
        assertThat(decision.allowed()).isTrue();
        assertThat(ReassignPolicy.availableAt(order)).isNull();
    }

    @Test
    void staffCourierCanBeSwappedAnytime() {
        order.setDeliveryPerson(null);
        order.setStaffCourier(new StaffCourier());

        assertThat(ReassignPolicy.kindOf(order)).isEqualTo(CourierKind.STAFF);
        assertThat(ReassignPolicy.decide(order, ASSIGNED, STALE_S).allowed()).isTrue();
    }

    @Test
    void freeCourierOnlyAfterNoShowMinutes() {
        shift(ShiftMode.FREE, null);
        courier.setLastSeenAt(ASSIGNED.plusMinutes(9));

        Decision early = ReassignPolicy.decide(order, ASSIGNED.plusMinutes(9), STALE_S);
        assertThat(ReassignPolicy.kindOf(order)).isEqualTo(CourierKind.FREE);
        assertThat(early.allowed()).isFalse();
        assertThat(early.availableAt()).isEqualTo(ASSIGNED.plusMinutes(10));
        assertThat(early.reason()).contains("19:10");

        courier.setLastSeenAt(ASSIGNED.plusMinutes(10));
        assertThat(ReassignPolicy.decide(order, ASSIGNED.plusMinutes(10), STALE_S).allowed()).isTrue();
    }

    @Test
    void noShowMinutesComeFromTheRestaurant() {
        shift(ShiftMode.FREE, null);
        restaurant.setCourierNoShowMinutes(5);

        assertThat(ReassignPolicy.decide(order, ASSIGNED.plusMinutes(6), STALE_S).allowed()).isTrue();
    }

    @Test
    void freeCourierAtTheStoreCannotBeSwapped() {
        shift(ShiftMode.FREE, null);
        courier.setLastLatitude(-26.9195);
        courier.setLastLongitude(-49.0662);
        courier.setLastSeenAt(ASSIGNED.plusMinutes(20));

        Decision decision = ReassignPolicy.decide(order, ASSIGNED.plusMinutes(20), STALE_S);
        assertThat(decision.allowed()).isFalse();
        assertThat(decision.courierAtStore()).isTrue();
    }

    @Test
    void staleLocationAtTheStoreDoesNotCountAsArrived() {
        shift(ShiftMode.FREE, null);
        courier.setLastLatitude(-26.9195);
        courier.setLastLongitude(-49.0662);
        courier.setLastSeenAt(ASSIGNED.plusMinutes(1));

        assertThat(ReassignPolicy.decide(order, ASSIGNED.plusMinutes(20), STALE_S).allowed()).isTrue();
    }

    @Test
    void nobodyCanBeSwappedAfterPickup() {
        shift(ShiftMode.FIXED, restaurant);
        order.setStatus(OrderStatus.OUT_FOR_DELIVERY);
        order.setPickedUpAt(ASSIGNED.plusMinutes(5));

        Decision decision = ReassignPolicy.decide(order, ASSIGNED.plusMinutes(30), STALE_S);
        assertThat(decision.allowed()).isFalse();
        assertThat(decision.reason()).contains("saiu para entrega");
    }
}
