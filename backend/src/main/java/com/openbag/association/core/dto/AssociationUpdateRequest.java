package com.openbag.association.core.dto;

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
@Schema(description = "Atualização dos dados da associação (o CNPJ não pode ser alterado)")
public class AssociationUpdateRequest {

    @Valid
    @NotNull(message = "Dados da associação são obrigatórios")
    private AssociationDataRequest association;

    @Valid
    private AddressDTO address;
}
