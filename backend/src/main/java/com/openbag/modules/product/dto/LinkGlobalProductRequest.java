package com.openbag.modules.product.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * DTO para vincular produto global ao restaurante
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class LinkGlobalProductRequest {

    @NotNull(message = "ID do produto global é obrigatório")
    private Long globalProductId;

    @NotNull(message = "Preço de venda é obrigatório")
    @DecimalMin(value = "0.0", message = "Preço deve ser maior ou igual a zero")
    private BigDecimal restaurantPrice;

    private boolean isAvailable = true;
}
