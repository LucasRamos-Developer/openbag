package com.openbag.restaurant.menu.dto;

import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MenuItemRequest {

    @NotNull(message = "Seção é obrigatória")
    private Long sectionId;

    @NotBlank(message = "Nome do item é obrigatório")
    @Size(max = 100, message = "Nome deve ter no máximo 100 caracteres")
    private String name;

    @Size(max = 500, message = "Descrição deve ter no máximo 500 caracteres")
    private String description;

    @NotNull(message = "Preço é obrigatório")
    @DecimalMin(value = "0.01", message = "Preço deve ser maior que zero")
    @Digits(integer = 8, fraction = 2, message = "Preço inválido")
    private BigDecimal price;

    // Preço promocional (menor que o preço normal); null = sem promoção
    @DecimalMin(value = "0.01", message = "Preço promocional deve ser maior que zero")
    @Digits(integer = 8, fraction = 2, message = "Preço promocional inválido")
    private BigDecimal promotionalPrice;

    @Min(value = 0, message = "Tempo de preparo não pode ser negativo")
    @Max(value = 240, message = "Tempo de preparo máximo de 240 minutos")
    private Integer preparationTime;

    // Selos livres; normalizados no serviço (máximo 2, até 20 caracteres)
    private List<String> badges;

    private Boolean available;

    private Boolean active;
}
