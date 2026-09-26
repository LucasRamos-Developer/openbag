package com.openbag.modules.menu.dto;

import com.openbag.modules.menu.entity.MenuSection;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MenuSectionDTO {

    private Long id;
    private String name;
    private String description;
    private int position;
    private boolean active;
    private List<MenuItemDTO> items;
    private List<ComboDTO> combos;

    public static MenuSectionDTO from(MenuSection section, List<MenuItemDTO> items, List<ComboDTO> combos) {
        return MenuSectionDTO.builder()
                .id(section.getId())
                .name(section.getName())
                .description(section.getDescription())
                .position(section.getPosition())
                .active(section.isActive())
                .items(items)
                .combos(combos)
                .build();
    }
}
