package com.openbag.annotation;

import org.springframework.security.access.prepost.PreAuthorize;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Anotação para verificar se o usuário logado pode gerenciar uma organização/associação específica
 * 
 * Verifica se:
 * - O usuário é o administrador da organização
 * - OU o usuário é ADMIN do sistema
 * 
 * Uso: @IsAssociationManager em um método que tenha um parâmetro chamado 'organizationId' ou 'id'
 * 
 * Exemplo:
 * @IsAssociationManager
 * public ResponseEntity<?> updateOrganization(@PathVariable Long id, @RequestBody OrganizationDTO dto) { ... }
 */
@Target({ElementType.METHOD})
@Retention(RetentionPolicy.RUNTIME)
@PreAuthorize("@authorizationService.canManageOrganization(principal.id, #id != null ? #id : #organizationId)")
public @interface IsAssociationManager {
}
