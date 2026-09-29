package com.openbag.restaurant.menu.dto;

import com.openbag.restaurant.catalog.entity.CustomizationGroup;
import com.openbag.restaurant.catalog.entity.CustomizationOption;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.Comparator;
import java.util.List;

/**
 * Grupo de complementos (ex: "Ponto da carne", "Adicionais") com suas opções
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomizationGroupDTO {

    private Long id;
    private String name;
    private boolean required;
    private int minSelections;
    private int maxSelections;
    private int position;
    private List<Option> options;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Option {
        private Long id;
        private String name;
        private BigDecimal priceModifier;
        private boolean available;
        private int displayOrder;

        public static Option from(CustomizationOption option) {
            return new Option(option.getId(), option.getName(), option.getPriceModifier(), option.isAvailable(),
                    option.getDisplayOrder() != null ? option.getDisplayOrder() : 0);
        }
    }

    public static CustomizationGroupDTO from(CustomizationGroup group) {
        return CustomizationGroupDTO.builder()
                .id(group.getId())
                .name(group.getName())
                .required(group.isRequired())
                .minSelections(group.getMinSelections() != null ? group.getMinSelections() : 0)
                .maxSelections(group.getMaxSelections() != null ? group.getMaxSelections() : 1)
                .position(group.getPosition() != null ? group.getPosition() : 0)
                .options(group.getOptions().stream()
                        .sorted(Comparator.comparing((CustomizationOption o) -> o.getDisplayOrder() != null ? o.getDisplayOrder() : 0)
                                .thenComparing(CustomizationOption::getId))
                        .map(Option::from)
                        .toList())
                .build();
    }
}
