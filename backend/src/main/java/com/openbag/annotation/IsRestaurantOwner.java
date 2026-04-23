package com.openbag.annotation;

import org.springframework.security.access.prepost.PreAuthorize;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Anotação para verificar se o usuário logado é o dono de um restaurante específico
 * 
 * Uso: @IsRestaurantOwner em um método que tenha um parâmetro chamado 'restaurantId' ou 'id'
 * 
 * Exemplo:
 * @IsRestaurantOwner
 * public ResponseEntity<?> updateRestaurant(@PathVariable Long id, @RequestBody RestaurantDTO dto) { ... }
 */
@Target({ElementType.METHOD})
@Retention(RetentionPolicy.RUNTIME)
@PreAuthorize("@authorizationService.canManageRestaurant(principal.id, #id != null ? #id : #restaurantId)")
public @interface IsRestaurantOwner {
}
