package com.openbag.modules.organization.dto;

import com.openbag.modules.user.dto.AddressDTO;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Cadastro completo de uma associação/cooperativa com seu gestor")
public class AssociationOnboardingRequest {

    @Valid
    @NotNull(message = "Dados do gestor são obrigatórios")
    private AccountRequest manager;

    @Valid
    @NotNull(message = "Dados da associação são obrigatórios")
    private AssociationDataRequest association;

    @Valid
    @NotNull(message = "Endereço é obrigatório")
    private AddressDTO address;
}
