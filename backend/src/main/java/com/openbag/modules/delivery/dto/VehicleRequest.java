package com.openbag.modules.delivery.dto;

import com.openbag.enums.VehicleType;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class VehicleRequest {

    @NotNull(message = "Tipo de veículo é obrigatório")
    private VehicleType type;

    @Size(max = 20, message = "Placa deve ter no máximo 20 caracteres")
    private String plate;

    @Size(max = 50, message = "Modelo deve ter no máximo 50 caracteres")
    private String model;

    @Size(max = 30, message = "Cor deve ter no máximo 30 caracteres")
    private String color;
}
