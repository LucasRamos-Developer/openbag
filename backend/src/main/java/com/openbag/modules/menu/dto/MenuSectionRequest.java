package com.openbag.modules.menu.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MenuSectionRequest {

    @NotBlank(message = "Nome da seção é obrigatório")
    @Size(max = 80, message = "Nome deve ter no máximo 80 caracteres")
    private String name;

    @Size(max = 300, message = "Descrição deve ter no máximo 300 caracteres")
    private String description;

    // Chave do ícone (catálogo do frontend); null = sem ícone
    @Pattern(regexp = "^[a-z_]{1,30}$", message = "Ícone inválido")
    private String icon;

    // null mantém o valor atual (na criação, a seção nasce ativa)
    private Boolean active;
}
