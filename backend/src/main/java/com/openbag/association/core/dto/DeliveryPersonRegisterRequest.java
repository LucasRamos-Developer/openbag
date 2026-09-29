package com.openbag.association.core.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Auto-cadastro do entregador. Informe inviteCode (entra ativo) ou organizationId (fica aguardando aprovação)")
public class DeliveryPersonRegisterRequest {

    @Valid
    @NotNull(message = "Dados da conta são obrigatórios")
    private AccountRequest account;

    @Valid
    @NotNull(message = "Dados do entregador são obrigatórios")
    private DeliveryPersonDataRequest deliveryPerson;

    @Schema(description = "Associação para a qual o entregador solicita entrada")
    private Long organizationId;

    @Schema(description = "Código de convite gerado pela associação", example = "K7M2QX9A")
    private String inviteCode;
}
