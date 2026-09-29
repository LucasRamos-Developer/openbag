package com.openbag.association.core.dto;

import com.openbag.association.core.entity.OrganizationType;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Dados cadastrais da associação/cooperativa")
public class AssociationDataRequest {

    @NotNull(message = "Tipo é obrigatório")
    private OrganizationType type;

    @NotBlank(message = "Razão social é obrigatória")
    @Size(max = 100, message = "Razão social deve ter no máximo 100 caracteres")
    private String companyName;

    @NotBlank(message = "Nome fantasia é obrigatório")
    @Size(max = 100, message = "Nome fantasia deve ter no máximo 100 caracteres")
    private String tradingName;

    @NotBlank(message = "CNPJ é obrigatório")
    @Size(max = 18, message = "CNPJ deve ter no máximo 18 caracteres")
    @Schema(example = "11.222.333/0001-81")
    private String cnpj;

    @Size(max = 500, message = "Descrição deve ter no máximo 500 caracteres")
    private String description;

    @NotBlank(message = "Telefone é obrigatório")
    @Size(max = 15, message = "Telefone deve ter no máximo 15 caracteres")
    private String phoneNumber;

    @Email(message = "Email de contato deve ter um formato válido")
    @Size(max = 100, message = "Email de contato deve ter no máximo 100 caracteres")
    private String contactEmail;
}
