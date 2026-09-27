package com.openbag.modules.restaurant.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Dados gerais do restaurante editados pelo dono (aba Loja › Geral).
 * O slug não muda com o nome, para não quebrar links e SEO.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class RestaurantProfileRequest {

    @NotBlank(message = "Nome do restaurante é obrigatório")
    @Size(max = 100, message = "Nome deve ter no máximo 100 caracteres")
    private String name;

    @Size(max = 500, message = "Descrição deve ter no máximo 500 caracteres")
    private String description;

    @NotBlank(message = "Telefone do restaurante é obrigatório")
    @Size(max = 15, message = "Telefone deve ter no máximo 15 caracteres")
    private String phoneNumber;

    @NotEmpty(message = "Escolha pelo menos uma categoria")
    private List<Long> categoryIds;

    /** Nula ou vazia para não informar */
    @Pattern(regexp = "^(\\$\\${0,3})?$", message = "Faixa de preço deve ser de $ a $$$$")
    private String priceRange;
}
