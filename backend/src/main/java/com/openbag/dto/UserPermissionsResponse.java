package com.openbag.dto;

import com.openbag.entity.User;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.stream.Collectors;

/**
 * DTO para resposta com permissões do usuário
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserPermissionsResponse {
    
    private List<RoleDTO> roles;
    private List<PermissionDTO> permissions;

    /**
     * Constrói a resposta a partir de um usuário
     */
    public static UserPermissionsResponse fromUser(User user) {
        List<RoleDTO> roles = user.getRoles().stream()
                .map(RoleDTO::simple)
                .collect(Collectors.toList());

        List<PermissionDTO> permissions = user.getAllPermissions().stream()
                .map(PermissionDTO::new)
                .collect(Collectors.toList());

        return UserPermissionsResponse.builder()
                .roles(roles)
                .permissions(permissions)
                .build();
    }
}
