package com.openbag.modules.product.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

/**
 * DTO para criação de grupo de customização
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CustomizationGroupRequest {

    @NotBlank(message = "Nome do grupo é obrigatório")
    @Size(max = 100, message = "Nome do grupo deve ter no máximo 100 caracteres")
    private String name;

    private boolean isRequired = false;

    @Min(value = 0, message = "Mínimo de seleções deve ser >= 0")
    private Integer minSelections = 0;

    @Min(value = 1, message = "Máximo de seleções deve ser >= 1")
    private Integer maxSelections = 1;

    @NotNull(message = "Produto é obrigatório")
    private Long productId;

    @Valid
    private List<CustomizationOptionRequest> options = new ArrayList<>();
}
