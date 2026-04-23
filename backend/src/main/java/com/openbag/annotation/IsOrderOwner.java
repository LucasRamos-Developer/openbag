package com.openbag.annotation;

import org.springframework.security.access.prepost.PreAuthorize;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Anotação para verificar se o usuário logado pode visualizar/gerenciar um pedido específico
 * 
 * Verifica se:
 * - O usuário é dono do pedido (quem fez o pedido)
 * - OU o usuário é dono do restaurante do pedido
 * - OU o usuário é ADMIN
 * 
 * Uso: @IsOrderOwner em um método que tenha um parâmetro chamado 'orderId' ou 'id'
 * 
 * Exemplo:
 * @IsOrderOwner
 * public ResponseEntity<?> getOrder(@PathVariable Long id) { ... }
 */
@Target({ElementType.METHOD})
@Retention(RetentionPolicy.RUNTIME)
@PreAuthorize("@authorizationService.canViewOrder(principal.id, #id != null ? #id : #orderId)")
public @interface IsOrderOwner {
}
