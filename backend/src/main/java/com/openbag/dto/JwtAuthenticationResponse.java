package com.openbag.dto;

import com.openbag.entity.User;
import com.openbag.enums.UserType;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.stream.Collectors;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class JwtAuthenticationResponse {

    private String accessToken;
    private String tokenType = "Bearer";
    private UserDto user;
    private List<RoleDTO> roles;
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
    public static class UserDto {
        private Long id;
        private String fullName;
        private String email;
        private String phoneNumber;
        
        /**
         * @deprecated Use roles instead
         */
        @Deprecated
        private UserType userType;
        
        private boolean isActive;
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
