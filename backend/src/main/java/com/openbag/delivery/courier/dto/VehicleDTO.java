package com.openbag.delivery.courier.dto;

import com.openbag.delivery.courier.entity.VehicleType;
import com.openbag.delivery.courier.entity.Vehicle;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VehicleDTO {

    private Long id;
    private VehicleType type;
    private String plate;
    private String model;
    private String color;
    private String photoUrl;
    private boolean active;

    // Custos informados para o resultado estimado (nulos quando não informados)
    private BigDecimal fuelConsumptionKmPerLiter;
    private BigDecimal fuelPricePerLiter;
    private BigDecimal maintenancePerKm;
    private BigDecimal depreciationPerKm;

    public static VehicleDTO from(Vehicle vehicle, boolean active) {
        return VehicleDTO.builder()
                .id(vehicle.getId())
                .type(vehicle.getType())
                .plate(vehicle.getPlate())
                .model(vehicle.getModel())
                .color(vehicle.getColor())
                .photoUrl(vehicle.getPhotoUrl())
                .active(active)
                .fuelConsumptionKmPerLiter(vehicle.getFuelConsumptionKmPerLiter())
                .fuelPricePerLiter(vehicle.getFuelPricePerLiter())
                .maintenancePerKm(vehicle.getMaintenancePerKm())
                .depreciationPerKm(vehicle.getDepreciationPerKm())
                .build();
    }
}
