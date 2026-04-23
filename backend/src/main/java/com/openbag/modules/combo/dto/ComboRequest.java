package com.openbag.modules.combo.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

/**
 * DTO para criação/atualização de combo
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ComboRequest {

    @NotBlank(message = "Nome do combo é obrigatório")
    @Size(max = 200, message = "Nome do combo deve ter no máximo 200 caracteres")
    private String name;

    @Size(max = 1000, message = "Descrição deve ter no máximo 1000 caracteres")
    private String description;

    @NotNull(message = "Preço do combo é obrigatório")
    private BigDecimal price;

    private String imageUrl;

    private boolean isAvailable = true;

    @NotNull(message = "Restaurante é obrigatório")
    private Long restaurantId;

    private Long categoryId;

    @Valid
    private List<ComboItemRequest> items = new ArrayList<>();
}
