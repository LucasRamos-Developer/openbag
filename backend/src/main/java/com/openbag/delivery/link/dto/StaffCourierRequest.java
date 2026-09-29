package com.openbag.delivery.link.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

/**
 * Cadastro de entregador da equipe própria; sem valor por entrega, ele recebe a taxa cobrada do cliente
 */
public record StaffCourierRequest(
        @NotBlank(message = "Informe o nome") @Size(max = 100, message = "Nome deve ter no máximo 100 caracteres") String name,
        @Size(max = 20, message = "Telefone deve ter no máximo 20 caracteres") String phone,
        @DecimalMin(value = "0.00", message = "O valor por entrega não pode ser negativo") BigDecimal feePerDelivery) {
}
