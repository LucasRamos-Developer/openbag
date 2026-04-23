package com.openbag.dto;

import com.openbag.entity.Permission;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO para representação de Permission
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PermissionDTO {
    
    private Long id;
    private String name;
    private String description;
    private String category;

    /**
     * Constrói um PermissionDTO a partir de uma entidade Permission
     */
    public PermissionDTO(Permission permission) {
        this.id = permission.getId();
        this.name = permission.getName();
        this.description = permission.getDescription();
        this.category = permission.getCategory();
    }
}
