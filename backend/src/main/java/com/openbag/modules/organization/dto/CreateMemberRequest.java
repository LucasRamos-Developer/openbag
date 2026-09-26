package com.openbag.modules.organization.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Cadastro de um associado feito diretamente pelo gestor")
public class CreateMemberRequest {

    @Valid
    @NotNull(message = "Dados da conta são obrigatórios")
    private AccountRequest account;

    @Valid
    @NotNull(message = "Dados do entregador são obrigatórios")
    private DeliveryPersonDataRequest deliveryPerson;
}
