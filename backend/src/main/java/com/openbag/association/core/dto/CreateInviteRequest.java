package com.openbag.association.core.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Geração de código de convite")
public class CreateInviteRequest {

    @Min(value = 1, message = "Validade mínima de 1 dia")
    @Max(value = 90, message = "Validade máxima de 90 dias")
    @Schema(description = "Validade em dias (padrão 7)", example = "7")
    private Integer expiresInDays;

    @Min(value = 1, message = "Limite mínimo de 1 uso")
    @Max(value = 1000, message = "Limite máximo de 1000 usos")
    @Schema(description = "Quantidade máxima de usos (vazio = ilimitado)", example = "10")
    private Integer maxUses;
}
