package com.openbag.modules.delivery.dto;

import com.openbag.enums.VehicleType;
import com.openbag.modules.delivery.entity.Vehicle;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

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

    public static VehicleDTO from(Vehicle vehicle, boolean active) {
        return VehicleDTO.builder()
                .id(vehicle.getId())
                .type(vehicle.getType())
                .plate(vehicle.getPlate())
                .model(vehicle.getModel())
                .color(vehicle.getColor())
                .photoUrl(vehicle.getPhotoUrl())
                .active(active)
                .build();
    }
}
