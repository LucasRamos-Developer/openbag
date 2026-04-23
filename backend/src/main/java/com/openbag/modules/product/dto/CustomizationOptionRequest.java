package com.openbag.modules.product.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * DTO para criação de opção de customização
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CustomizationOptionRequest {

    @NotBlank(message = "Nome da opção é obrigatório")
    @Size(max = 100, message = "Nome da opção deve ter no máximo 100 caracteres")
    private String name;

    @NotNull(message = "Preço adicional é obrigatório")
    private BigDecimal priceModifier = BigDecimal.ZERO;

    private boolean isAvailable = true;

    private Integer displayOrder = 0;
}
