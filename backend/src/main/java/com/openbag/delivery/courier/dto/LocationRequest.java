package com.openbag.delivery.courier.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class LocationRequest {

    @NotNull(message = "Localização é obrigatória")
    @DecimalMin("-90.0")
    @DecimalMax("90.0")
    private Double latitude;

    @NotNull(message = "Localização é obrigatória")
    @DecimalMin("-180.0")
    @DecimalMax("180.0")
    private Double longitude;
}
