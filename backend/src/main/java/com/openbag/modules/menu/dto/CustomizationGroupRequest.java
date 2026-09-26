package com.openbag.modules.menu.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

/**
 * Cria ou substitui um grupo de complementos inteiro, com as opções na ordem de exibição.
 * Opções com id são atualizadas; sem id são criadas; as ausentes são removidas.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CustomizationGroupRequest {

    @NotBlank(message = "Nome do grupo é obrigatório")
    @Size(max = 100, message = "Nome deve ter no máximo 100 caracteres")
    private String name;

    @NotNull(message = "Mínimo de escolhas é obrigatório")
    @Min(value = 0, message = "Mínimo não pode ser negativo")
    private Integer minSelections;

    @NotNull(message = "Máximo de escolhas é obrigatório")
    @Min(value = 1, message = "Máximo deve ser pelo menos 1")
    private Integer maxSelections;

    @Valid
    @NotEmpty(message = "Adicione pelo menos uma opção")
    private List<OptionRequest> options;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class OptionRequest {

        private Long id;

        @NotBlank(message = "Nome da opção é obrigatório")
        @Size(max = 100, message = "Nome da opção deve ter no máximo 100 caracteres")
        private String name;

        @NotNull(message = "Preço adicional é obrigatório (use 0 para grátis)")
        @DecimalMin(value = "0.00", message = "Preço adicional não pode ser negativo")
        private BigDecimal priceModifier;

        private Boolean available;
    }
}
