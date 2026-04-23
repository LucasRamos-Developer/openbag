package com.openbag.modules.user.dto;

import com.openbag.modules.user.entity.Role;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Set;
import java.util.stream.Collectors;

/**
 * DTO para representação de Role
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RoleDTO {
    
    private Long id;
    private String name;
    private String description;
    private Set<String> permissions;

    /**
     * Constrói um RoleDTO a partir de uma entidade Role
     */
    public RoleDTO(Role role) {
        this.id = role.getId();
        this.name = role.getName();
        this.description = role.getDescription();
        this.permissions = role.getPermissions().stream()
                .map(permission -> permission.getName())
                .collect(Collectors.toSet());
    }

    /**
     * Constrói um RoleDTO sem as permissões (versão simplificada)
     */
    public static RoleDTO simple(Role role) {
        return RoleDTO.builder()
                .id(role.getId())
                .name(role.getName())
                .description(role.getDescription())
                .build();
    }
}
