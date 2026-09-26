package com.openbag.modules.organization.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Motivo de uma decisão (recusa, suspensão, desligamento)")
public class ReasonRequest {

    @Size(max = 500, message = "Motivo deve ter no máximo 500 caracteres")
    private String reason;
}
