package com.openbag.association.core.dto;

import com.openbag.delivery.courier.entity.VehicleType;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Dados profissionais do entregador")
public class DeliveryPersonDataRequest {

    @NotBlank(message = "CPF é obrigatório")
    @Size(max = 14, message = "CPF deve ter no máximo 14 caracteres")
    @Schema(example = "123.456.789-09")
    private String documentNumber;

    @NotBlank(message = "CNH é obrigatória")
    @Size(max = 20, message = "CNH deve ter no máximo 20 caracteres")
    private String driverLicense;

    @NotNull(message = "Tipo de veículo é obrigatório")
    private VehicleType vehicleType;

    @Size(max = 20, message = "Placa deve ter no máximo 20 caracteres")
    private String vehiclePlate;

    @Size(max = 50, message = "Modelo deve ter no máximo 50 caracteres")
    private String vehicleModel;

    @Size(max = 30, message = "Cor deve ter no máximo 30 caracteres")
    private String vehicleColor;
}
