package com.openbag.modules.user.dto;

import com.openbag.enums.UserType;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Dados para registro de novo usuário")
public class RegisterRequest {

    @NotBlank(message = "Nome completo é obrigatório")
    @Size(max = 100, message = "Nome completo deve ter no máximo 100 caracteres")
    @Schema(description = "Nome completo do usuário", example = "João da Silva", required = true, maxLength = 100)
    private String fullName;

    @NotBlank(message = "Email é obrigatório")
    @Email(message = "Email deve ter um formato válido")
    @Size(max = 100, message = "Email deve ter no máximo 100 caracteres")
    @Schema(description = "Email do usuário", example = "joao.silva@example.com", required = true, maxLength = 100)
    private String email;

    @NotBlank(message = "Telefone é obrigatório")
    @Size(max = 15, message = "Telefone deve ter no máximo 15 caracteres")
    @Schema(description = "Telefone do usuário", example = "(11) 98765-4321", required = true, maxLength = 15)
    private String phoneNumber;

    @NotBlank(message = "Senha é obrigatória")
    @Size(min = 6, max = 100, message = "Senha deve ter entre 6 e 100 caracteres")
    @Schema(description = "Senha do usuário", example = "senhaSegura123", required = true, minLength = 6, maxLength = 100)
    private String password;

    /**
     * @deprecated Use roles instead
     */
    @Deprecated
    @Schema(description = "Tipo de usuário (deprecated, use roles)", deprecated = true)
    private UserType userType = UserType.CUSTOMER;

    /**
     * Lista de roles para o usuário (opcional)
     * Se não fornecido, o usuário receberá a role CUSTOMER por padrão
     */
    @Schema(description = "Lista de roles do usuário", example = "[\"CUSTOMER\", \"RESTAURANT\"]", required = false)
    private List<String> roles;
}
