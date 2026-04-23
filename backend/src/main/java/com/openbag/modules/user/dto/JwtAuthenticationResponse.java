package com.openbag.modules.user.dto;

import com.openbag.modules.user.entity.User;
import com.openbag.enums.UserType;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.stream.Collectors;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Resposta de autenticação com token JWT e dados do usuário")
public class JwtAuthenticationResponse {

    @Schema(description = "Token JWT para autenticação", example = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...")
    private String accessToken;
    
    @Schema(description = "Tipo do token", example = "Bearer", defaultValue = "Bearer")
    private String tokenType = "Bearer";
    
    @Schema(description = "Dados do usuário autenticado")
    private UserDto user;
    
    @Schema(description = "Roles do usuário")
    private List<RoleDTO> roles;
    
    @Schema(description = "Permissões do usuário")
    private List<String> permissions;

    public JwtAuthenticationResponse(String accessToken, UserDto user) {
        this.accessToken = accessToken;
        this.user = user;
    }

    /**
     * Construtor completo com roles e permissões
     */
    public JwtAuthenticationResponse(String accessToken, UserDto user, List<RoleDTO> roles, List<String> permissions) {
        this.accessToken = accessToken;
        this.user = user;
        this.roles = roles;
        this.permissions = permissions;
    }

    @Data
    @NoArgsConstructor
    @Schema(description = "Dados resumidos do usuário")
    public static class UserDto {
        @Schema(description = "ID do usuário", example = "1")
        private Long id;
        
        @Schema(description = "Nome completo do usuário", example = "João da Silva")
        private String fullName;
        
        @Schema(description = "Email do usuário", example = "joao.silva@example.com")
        private String email;
        
        @Schema(description = "Telefone do usuário", example = "(11) 98765-4321")
        private String phoneNumber;
        
        /**
         * @deprecated Use roles instead
         */
        @Deprecated
        @Schema(description = "Tipo de usuário (deprecated, use roleNames)", deprecated = true)
        private UserType userType;
        
        @Schema(description = "Indica se o usuário está ativo", example = "true")
        private boolean isActive;
        
        @Schema(description = "Lista de nomes das roles do usuário", example = "[\"CUSTOMER\", \"RESTAURANT\"]")
        private List<String> roleNames;

        public UserDto(User user) {
            this.id = user.getId();
            this.fullName = user.getFullName();
            this.email = user.getEmail();
            this.phoneNumber = user.getPhoneNumber();
            this.userType = user.getUserType(); // mantido para compatibilidade
            this.isActive = user.isActive();
            this.roleNames = user.getRoles().stream()
                    .map(role -> role.getName())
                    .collect(Collectors.toList());
        }
    }
}
