package com.openbag.security;

import com.openbag.modules.shared.service.AuthorizationService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.PermissionEvaluator;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Component;

import java.io.Serializable;

/**
 * Implementação customizada de PermissionEvaluator para Spring Security
 * Permite usar hasPermission() nas expressões @PreAuthorize
 * 
 * Exemplo de uso:
 * @PreAuthorize("hasPermission(#restaurantId, 'Restaurant', 'EDIT')")
 * public void updateRestaurant(Long restaurantId, RestaurantDTO dto) { ... }
 */
@Component
@Slf4j
public class CustomPermissionEvaluator implements PermissionEvaluator {

    @Autowired
    private AuthorizationService authorizationService;

    /**
     * Avalia se o usuário tem permissão sobre um objeto específico
     * 
     * @param authentication Autenticação do usuário
     * @param targetDomainObject O ID do objeto (ex: restaurantId, orderId)
     * @param permission A permissão requerida (ex: "EDIT", "VIEW", "DELETE")
     * @return true se o usuário tem a permissão
     */
    @Override
    public boolean hasPermission(Authentication authentication, Object targetDomainObject, Object permission) {
        if (authentication == null || targetDomainObject == null || permission == null) {
            log.debug("hasPermission: parâmetros nulos");
            return false;
        }

        String targetType = targetDomainObject.getClass().getSimpleName();
        return hasPermission(authentication, (Serializable) targetDomainObject, targetType, permission);
    }

    /**
     * Avalia se o usuário tem permissão sobre um tipo específico de objeto
     * 
     * @param authentication Autenticação do usuário
     * @param targetId ID do objeto alvo
     * @param targetType Tipo do objeto (ex: "Restaurant", "Order", "Organization")
     * @param permission A permissão requerida (ex: "EDIT", "VIEW", "DELETE")
     * @return true se o usuário tem a permissão
     */
    @Override
    public boolean hasPermission(Authentication authentication, Serializable targetId, 
                                String targetType, Object permission) {
        
        if (authentication == null || targetType == null || permission == null) {
            log.debug("hasPermission: parâmetros nulos");
            return false;
        }

        // Extrai o userId do principal
        Long userId = getUserId(authentication);
        if (userId == null) {
            log.debug("hasPermission: userId não encontrado no principal");
            return false;
        }

        Long entityId = null;
        if (targetId instanceof Long) {
            entityId = (Long) targetId;
        } else if (targetId instanceof String) {
            try {
                entityId = Long.parseLong((String) targetId);
            } catch (NumberFormatException e) {
                log.debug("hasPermission: targetId não é um Long válido: {}", targetId);
                return false;
            }
        }

        if (entityId == null) {
            log.debug("hasPermission: entityId é null");
            return false;
        }

        String permissionStr = permission.toString().toUpperCase();
        log.debug("Verificando permissão: user={}, targetType={}, targetId={}, permission={}", 
                userId, targetType, entityId, permissionStr);

        // Delega para o AuthorizationService baseado no tipo do objeto
        return switch (targetType.toUpperCase()) {
            case "RESTAURANT" -> {
                if ("EDIT".equals(permissionStr) || "DELETE".equals(permissionStr) || "MANAGE".equals(permissionStr)) {
                    yield authorizationService.canManageRestaurant(userId, entityId);
                }
                yield false;
            }
            case "ORDER" -> {
                if ("VIEW".equals(permissionStr) || "MANAGE".equals(permissionStr)) {
                    yield authorizationService.canViewOrder(userId, entityId);
                }
                if ("ASSIGN_DELIVERY".equals(permissionStr)) {
                    yield authorizationService.canAssignDelivery(userId, entityId);
                }
                yield false;
            }
            case "ORGANIZATION" -> {
                if ("MANAGE".equals(permissionStr) || "EDIT".equals(permissionStr)) {
                    yield authorizationService.canManageOrganization(userId, entityId);
                }
                yield false;
            }
            case "DELIVERYPERSON" -> {
                if ("MANAGE".equals(permissionStr) || "EDIT".equals(permissionStr)) {
                    yield authorizationService.canManageDeliveryPerson(userId, entityId);
                }
                yield false;
            }
            default -> {
                log.warn("Tipo de objeto não suportado: {}", targetType);
                yield false;
            }
        };
    }

    /**
     * Extrai o userId do Authentication principal
     */
    private Long getUserId(Authentication authentication) {
        if (authentication.getPrincipal() instanceof CustomUserDetailsService.CustomUserPrincipal principal) {
            return principal.getId();
        }
        return null;
    }
}
