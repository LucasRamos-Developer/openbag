package com.openbag.delivery.courier.service;

import com.openbag.delivery.courier.dto.CourierEarningsDTO;
import com.openbag.delivery.courier.entity.CourierShift;
import com.openbag.delivery.courier.entity.Vehicle;
import com.openbag.order.core.entity.Order;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/**
 * Custo estimado do veículo no período: km × (preço ÷ consumo + manutenção + depreciação). Cada entrega usa o
 * veículo do turno em que foi entregue e, sem turno, o veículo ativo. Só contas; quem chama busca os dados.
 */
final class VehicleCostEstimator {

    private VehicleCostEstimator() {
    }

    static CourierEarningsDTO.CostEstimate estimate(List<Order> delivered, Map<Long, Double> pickupKm,
                                                    List<CourierShift> shifts, Vehicle active, BigDecimal revenue) {
        // Km de cada veículo, com o pedido e até a retirada. Por id: o mesmo veículo pode vir como objetos
        // diferentes (pelo turno e pelo entregador)
        Map<Long, Vehicle> byId = new LinkedHashMap<>();
        Map<Long, Double> kmById = new LinkedHashMap<>();
        for (Order order : delivered) {
            Vehicle vehicle = vehicleAt(order.getDeliveredAt(), shifts, active);
            if (vehicle == null) {
                continue;
            }
            double km = Objects.requireNonNullElse(order.getDeliveryDistanceKm(), 0.0)
                    + Objects.requireNonNullElse(pickupKm.get(order.getId()), 0.0);
            byId.putIfAbsent(vehicle.getId(), vehicle);
            kmById.merge(vehicle.getId(), km, Double::sum);
        }
        if (byId.isEmpty() && active != null) {
            byId.put(active.getId(), active);
            kmById.put(active.getId(), 0.0);
        }
        if (byId.values().stream().noneMatch(Vehicle::hasCosts)) {
            return null;
        }

        BigDecimal fuel = null;
        BigDecimal maintenance = null;
        BigDecimal depreciation = null;
        boolean complete = true;
        List<CourierEarningsDTO.VehicleCost> vehicles = new ArrayList<>();
        for (Vehicle vehicle : byId.values()) {
            double vehicleKm = kmById.get(vehicle.getId());
            BigDecimal km = BigDecimal.valueOf(vehicleKm);
            boolean needsFuel = vehicle.isMotorized();
            boolean hasFuel = vehicle.getFuelConsumptionKmPerLiter() != null && vehicle.getFuelPricePerLiter() != null;
            if (needsFuel && hasFuel) {
                fuel = add(fuel, km.multiply(vehicle.getFuelPricePerLiter())
                        .divide(vehicle.getFuelConsumptionKmPerLiter(), 6, RoundingMode.HALF_UP));
            }
            if (vehicle.getMaintenancePerKm() != null) {
                maintenance = add(maintenance, km.multiply(vehicle.getMaintenancePerKm()));
            }
            if (vehicle.getDepreciationPerKm() != null) {
                depreciation = add(depreciation, km.multiply(vehicle.getDepreciationPerKm()));
            }
            boolean vehicleComplete = (!needsFuel || hasFuel) && vehicle.getMaintenancePerKm() != null
                    && vehicle.getDepreciationPerKm() != null;
            complete &= vehicleComplete || vehicleKm == 0;
            vehicles.add(new CourierEarningsDTO.VehicleCost(vehicle.getId(), name(vehicle), round(vehicleKm),
                    vehicleComplete));
        }

        fuel = money(fuel);
        maintenance = money(maintenance);
        depreciation = money(depreciation);
        BigDecimal total = money(add(add(add(null, fuel), maintenance), depreciation));
        if (total == null) {
            total = BigDecimal.ZERO.setScale(2);
        }
        double km = round(kmById.values().stream().mapToDouble(Double::doubleValue).sum());
        return new CourierEarningsDTO.CostEstimate(km, revenue, fuel, maintenance, depreciation, total,
                revenue.subtract(total), complete, vehicles);
    }

    /** Veículo do turno aberto na hora da entrega; sem turno, o ativo */
    private static Vehicle vehicleAt(LocalDateTime at, List<CourierShift> shifts, Vehicle active) {
        if (at != null) {
            for (CourierShift shift : shifts) {
                if (shift.getVehicle() != null && !shift.getStartedAt().isAfter(at)
                        && (shift.getEndedAt() == null || !shift.getEndedAt().isBefore(at))) {
                    return shift.getVehicle();
                }
            }
        }
        return active;
    }

    private static String name(Vehicle vehicle) {
        return vehicle.getModel() != null ? vehicle.getModel() : vehicle.getType().getDisplayName();
    }

    private static BigDecimal add(BigDecimal sum, BigDecimal value) {
        if (value == null) {
            return sum;
        }
        return sum == null ? value : sum.add(value);
    }

    private static BigDecimal money(BigDecimal value) {
        return value == null ? null : value.setScale(2, RoundingMode.HALF_UP);
    }

    private static double round(double km) {
        return Math.round(km * 10) / 10.0;
    }
}
