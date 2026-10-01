package com.openbag.delivery.courier.service;

import com.openbag.delivery.courier.dto.CourierEarningsDTO;
import com.openbag.delivery.courier.service.CourierWorkStats.Interval;
import com.openbag.order.core.entity.Order;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class CourierWorkStatsTest {

    private static final LocalDate DAY = LocalDate.of(2026, 9, 30);
    private static final LocalDateTime START = DAY.atStartOfDay();
    private static final LocalDateTime END = DAY.plusDays(1).atStartOfDay();

    private static Order order(long id, String fee, Double km, int assignedAt, int deliveredAt) {
        Order order = new Order();
        order.setId(id);
        order.setCourierFee(new BigDecimal(fee));
        order.setDeliveryDistanceKm(km);
        order.setAssignedAt(DAY.atTime(assignedAt / 100, assignedAt % 100));
        order.setDeliveredAt(DAY.atTime(deliveredAt / 100, deliveredAt % 100));
        return order;
    }

    @Test
    void aRouteWithTwoOrdersCountsTheSameMinutesOnce() {
        // Rota: os dois aceitos às 12h; um entregue 12h20 e o outro 12h40
        List<Order> route = List.of(order(1, "8.00", 2.0, 1200, 1220), order(2, "8.00", 3.0, 1200, 1240));

        CourierEarningsDTO.Stats stats = CourierWorkStats.of(route, Map.of(), List.of(), START, END, END);

        assertThat(stats.deliveringMinutes()).as("12h às 12h40").isEqualTo(40);
        assertThat(stats.perDelivery().minutes()).as("média de 20 e 40").isEqualTo(30);
    }

    @Test
    void shiftsAreCutToThePeriodAndAnOpenShiftCountsUntilNow() {
        List<Interval> shifts = List.of(
                new Interval(START.minusHours(2), START.plusHours(1)),   // começou ontem: conta 1 h
                new Interval(DAY.atTime(18, 0), null));                   // aberto: até agora (19h30)

        CourierEarningsDTO.Stats stats = CourierWorkStats.of(List.of(), Map.of(), shifts, START, END,
                DAY.atTime(19, 30));

        assertThat(stats.onlineMinutes()).isEqualTo(60 + 90);
    }

    @Test
    void withoutDeliveriesKmOrShiftsTheAveragesAreEmptyInsteadOfZero() {
        CourierEarningsDTO.Stats stats = CourierWorkStats.of(List.of(), Map.of(), List.of(), START, END, END);

        assertThat(stats.perDelivery()).isNull();
        assertThat(stats.perKm()).isNull();
        assertThat(stats.perHour()).isNull();
        assertThat(stats.totalKm()).isZero();
    }

    @Test
    void ordersWithoutDistanceDoNotPullTheKmAverageDown() {
        List<Order> orders = List.of(order(1, "8.00", 4.0, 1200, 1215), order(2, "8.00", null, 1300, 1315));

        CourierEarningsDTO.Stats stats = CourierWorkStats.of(orders, Map.of(2L, 1.5), List.of(), START, END, END);

        assertThat(stats.perDelivery().distanceKm()).isEqualTo(4.0);
        assertThat(stats.totalKm()).isEqualTo(5.5);
        assertThat(stats.perKm()).as("R$ 16 em 5,5 km").isEqualByComparingTo("2.91");
    }
}
