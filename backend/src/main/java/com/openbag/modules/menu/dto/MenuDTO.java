package com.openbag.modules.menu.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Cardápio completo: seções ordenadas com itens e combos
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class MenuDTO {

    private Long restaurantId;
    private List<MenuSectionDTO> sections;

    // Itens antigos ainda sem seção (só aparecem na visão do dono)
    private List<MenuItemDTO> unsectionedItems;
}
