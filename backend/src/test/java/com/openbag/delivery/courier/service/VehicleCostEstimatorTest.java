package com.openbag.delivery.courier.service;

import com.openbag.delivery.courier.dto.CourierEarningsDTO;
import com.openbag.delivery.courier.entity.CourierShift;
import com.openbag.delivery.courier.entity.Vehicle;
import com.openbag.delivery.courier.entity.VehicleType;
import com.openbag.order.core.entity.Order;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class VehicleCostEstimatorTest {

    private static final LocalDate DAY = LocalDate.of(2026, 9, 30);

    private static Vehicle moto(long id, String consumption, String price, String maintenance, String depreciation) {
        Vehicle vehicle = new Vehicle();
        vehicle.setId(id);
        vehicle.setType(VehicleType.MOTORCYCLE);
        vehicle.setModel("Honda CG 160");
        vehicle.setFuelConsumptionKmPerLiter(consumption == null ? null : new BigDecimal(consumption));
        vehicle.setFuelPricePerLiter(price == null ? null : new BigDecimal(price));
        vehicle.setMaintenancePerKm(maintenance == null ? null : new BigDecimal(maintenance));
        vehicle.setDepreciationPerKm(depreciation == null ? null : new BigDecimal(depreciation));
        return vehicle;
    }

    private static Order order(long id, double km, LocalDateTime deliveredAt) {
        Order order = new Order();
        order.setId(id);
        order.setDeliveryDistanceKm(km);
        order.setDeliveredAt(deliveredAt);
        order.setCourierFee(new BigDecimal("8.00"));
        return order;
    }

    @Test
    void theExampleOfTheRoadmap() {
        // 386 km, 35 km/l, R$ 6,20/l, R$ 0,18/km e R$ 0,10/km
        Vehicle moto = moto(1, "35", "6.20", "0.18", "0.10");
        List<Order> orders = List.of(order(1, 300, DAY.atTime(12, 0)), order(2, 80, DAY.atTime(13, 0)));

        CourierEarningsDTO.CostEstimate cost = VehicleCostEstimator.estimate(orders, Map.of(2L, 6.0), List.of(), moto,
                new BigDecimal("520.00"));

        assertThat(cost.distanceKm()).isEqualTo(386.0);
        assertThat(cost.fuel()).isEqualByComparingTo("68.38");
        assertThat(cost.maintenance()).isEqualByComparingTo("69.48");
        assertThat(cost.depreciation()).isEqualByComparingTo("38.60");
        assertThat(cost.total()).isEqualByComparingTo("176.46");
        assertThat(cost.result()).isEqualByComparingTo("343.54");
        assertThat(cost.complete()).isTrue();
    }

    @Test
    void withoutAnyCostInformedThereIsNoEstimateInsteadOfZero() {
        Vehicle moto = moto(1, null, null, null, null);

        assertThat(VehicleCostEstimator.estimate(List.of(order(1, 5, DAY.atTime(12, 0))), Map.of(), List.of(), moto,
                new BigDecimal("8.00"))).isNull();
        assertThat(VehicleCostEstimator.estimate(List.of(), Map.of(), List.of(), null, BigDecimal.ZERO)).isNull();
    }

    @Test
    void aMissingPartStaysEmptyAndTheEstimateIsIncomplete() {
        Vehicle moto = moto(1, null, null, "0.20", null);

        CourierEarningsDTO.CostEstimate cost = VehicleCostEstimator.estimate(List.of(order(1, 10, DAY.atTime(12, 0))),
                Map.of(), List.of(), moto, new BigDecimal("8.00"));

        assertThat(cost.fuel()).isNull();
        assertThat(cost.depreciation()).isNull();
        assertThat(cost.maintenance()).isEqualByComparingTo("2.00");
        assertThat(cost.total()).isEqualByComparingTo("2.00");
        assertThat(cost.complete()).isFalse();
        assertThat(cost.vehicles()).singleElement().extracting(CourierEarningsDTO.VehicleCost::complete).isEqualTo(false);
    }

    @Test
    void aBicycleNeedsNoFuel() {
        Vehicle bike = new Vehicle();
        bike.setId(2L);
        bike.setType(VehicleType.BICYCLE);
        bike.setMaintenancePerKm(new BigDecimal("0.05"));
        bike.setDepreciationPerKm(new BigDecimal("0.02"));

        CourierEarningsDTO.CostEstimate cost = VehicleCostEstimator.estimate(List.of(order(1, 10, DAY.atTime(12, 0))),
                Map.of(), List.of(), bike, new BigDecimal("8.00"));

        assertThat(cost.fuel()).isNull();
        assertThat(cost.total()).isEqualByComparingTo("0.70");
        assertThat(cost.complete()).isTrue();
        assertThat(cost.vehicles().get(0).name()).isEqualTo("Bicicleta");
    }

    @Test
    void eachDeliveryUsesTheVehicleOfItsShift() {
        Vehicle moto = moto(1, "35", "7.00", "0.10", "0.10");
        Vehicle car = moto(2, "10", "7.00", "0.30", "0.20");
        car.setType(VehicleType.CAR);
        car.setModel("Uno");
        CourierShift morning = new CourierShift();
        morning.setStartedAt(DAY.atTime(8, 0));
        morning.setEndedAt(DAY.atTime(12, 0));
        morning.setVehicle(car);
        List<Order> orders = List.of(order(1, 10, DAY.atTime(10, 0)), order(2, 10, DAY.atTime(19, 0)));

        // A entrega das 10h foi de carro (turno da manhã); a das 19h, sem turno, usa a moto ativa
        CourierEarningsDTO.CostEstimate cost = VehicleCostEstimator.estimate(orders, Map.of(), List.of(morning), moto,
                new BigDecimal("16.00"));

        assertThat(cost.vehicles()).extracting(CourierEarningsDTO.VehicleCost::name).containsExactly("Uno", "Honda CG 160");
        assertThat(cost.fuel()).as("10 km × 7 ÷ 10 + 10 km × 7 ÷ 35").isEqualByComparingTo("9.00");
        assertThat(cost.total()).isEqualByComparingTo("16.00");
        assertThat(cost.result()).isEqualByComparingTo("0.00");
    }
}
