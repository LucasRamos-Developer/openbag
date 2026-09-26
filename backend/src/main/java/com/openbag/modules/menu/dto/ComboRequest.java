package com.openbag.modules.menu.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ComboRequest {

    @NotNull(message = "Seção é obrigatória")
    private Long sectionId;

    @NotBlank(message = "Nome do combo é obrigatório")
    @Size(max = 200, message = "Nome deve ter no máximo 200 caracteres")
    private String name;

    @Size(max = 1000, message = "Descrição deve ter no máximo 1000 caracteres")
    private String description;

    @NotNull(message = "Preço é obrigatório")
    @DecimalMin(value = "0.01", message = "Preço deve ser maior que zero")
    private BigDecimal price;

    private Boolean available;

    private Boolean active;

    @Valid
    @NotEmpty(message = "Adicione pelo menos um item ao combo")
    private List<ItemRequest> items;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ItemRequest {

        @NotNull(message = "Item é obrigatório")
        private Long productId;

        @NotNull(message = "Quantidade é obrigatória")
        @Min(value = 1, message = "Quantidade mínima é 1")
        @Max(value = 20, message = "Quantidade máxima é 20")
        private Integer quantity;
    }
}
