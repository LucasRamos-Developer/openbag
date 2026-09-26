package com.openbag.modules.menu.dto;

import com.openbag.modules.product.entity.CustomizationGroup;
import com.openbag.modules.product.entity.Product;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.Comparator;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MenuItemDTO {

    private Long id;
    private Long sectionId;
    private String name;
    private String description;
    private BigDecimal price;
    private BigDecimal promotionalPrice;
    private BigDecimal currentPrice;
    private String imageUrl;
    private boolean available;
    private boolean active;
    private Integer preparationTime;
    private int position;
    private List<CustomizationGroupDTO> customizationGroups;

    public static MenuItemDTO from(Product product) {
        return MenuItemDTO.builder()
                .id(product.getId())
                .sectionId(product.getMenuSection() != null ? product.getMenuSection().getId() : null)
                .name(product.getName())
                .description(product.getDescription())
                .price(product.getPrice())
                .promotionalPrice(product.getPromotionalPrice())
                .currentPrice(product.getCurrentPrice())
                .imageUrl(product.getImageUrl())
                .available(product.isAvailable())
                .active(product.isActive())
                .preparationTime(product.getPreparationTime())
                .position(product.getPosition() != null ? product.getPosition() : 0)
                .customizationGroups(product.getCustomizationGroups().stream()
                        .sorted(Comparator.comparing((CustomizationGroup g) -> g.getPosition() != null ? g.getPosition() : 0)
                                .thenComparing(CustomizationGroup::getId))
                        .map(CustomizationGroupDTO::from)
                        .toList())
                .build();
    }
}
