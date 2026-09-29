package com.openbag.delivery.courier.tracking;

import com.openbag.enums.OrderStatus;
import com.openbag.delivery.courier.entity.DeliveryPerson;
import com.openbag.delivery.link.entity.StaffCourier;
import com.openbag.order.core.entity.Order;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class CourierTrackingTest {

    private final DeliveryPerson courier = new DeliveryPerson();

    private Order order(long id, OrderStatus status, Integer sequence) {
        Order order = new Order();
        order.setId(id);
        order.setStatus(status);
        order.setRouteSequence(sequence);
        order.setDeliveryPerson(courier);
        return order;
    }

    @Test
    void soloOrderOnTheWayIsTrackable() {
        Order solo = order(1, OrderStatus.OUT_FOR_DELIVERY, null);

        assertThat(CourierTracking.isTrackable(solo, List.of(solo))).isTrue();
    }

    @Test
    void orderNotPickedUpYetIsNotTrackable() {
        Order ready = order(1, OrderStatus.READY_FOR_PICKUP, null);

        assertThat(CourierTracking.isTrackable(ready, List.of(ready))).isFalse();
    }

    @Test
    void secondStopOfARouteWaitsForTheFirstDelivery() {
        Order first = order(10, OrderStatus.OUT_FOR_DELIVERY, 1);
        Order second = order(11, OrderStatus.OUT_FOR_DELIVERY, 2);

        assertThat(CourierTracking.isTrackable(second, List.of(second, first))).isFalse();
        assertThat(CourierTracking.isTrackable(first, List.of(second, first))).isTrue();
    }

    @Test
    void secondStopBecomesTrackableAfterTheFirstIsDelivered() {
        Order first = order(10, OrderStatus.DELIVERED, 1);
        Order second = order(11, OrderStatus.OUT_FOR_DELIVERY, 2);

        assertThat(CourierTracking.isTrackable(second, List.of(first, second))).isTrue();
        assertThat(CourierTracking.currentStop(List.of(first, second))).contains(second);
    }

    @Test
    void storeOwnTeamIsNeverTracked() {
        Order staffOrder = order(1, OrderStatus.OUT_FOR_DELIVERY, null);
        staffOrder.setDeliveryPerson(null);
        staffOrder.setStaffCourier(new StaffCourier());

        assertThat(CourierTracking.isTrackable(staffOrder, List.of(staffOrder))).isFalse();
    }
}
