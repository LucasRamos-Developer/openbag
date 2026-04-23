package com.openbag.modules.combo.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO para item de combo
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ComboItemRequest {

    @NotNull(message = "ID do produto é obrigatório")
    private Long productId;

    @NotNull(message = "Quantidade é obrigatória")
    @Min(value = 1, message = "Quantidade deve ser >= 1")
    private Integer quantity = 1;
}
