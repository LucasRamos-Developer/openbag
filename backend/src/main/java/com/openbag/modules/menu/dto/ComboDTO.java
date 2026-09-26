package com.openbag.modules.menu.dto;

import com.openbag.modules.combo.entity.Combo;
import com.openbag.modules.combo.entity.ComboItem;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ComboDTO {

    private Long id;
    private Long sectionId;
    private String name;
    private String description;
    private BigDecimal price;
    private String imageUrl;
    private boolean available;
    private boolean active;
    private int position;
    private List<Item> items;

    // Soma dos itens comprados separadamente e quanto o cliente economiza
    private BigDecimal originalPrice;
    private BigDecimal savings;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Item {
        private Long productId;
        private String productName;
        private int quantity;
    }

    public static ComboDTO from(Combo combo) {
        BigDecimal original = combo.getComboItems().stream()
                .map(ComboItem::calculateIndividualPrice)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        return ComboDTO.builder()
                .id(combo.getId())
                .sectionId(combo.getMenuSection() != null ? combo.getMenuSection().getId() : null)
                .name(combo.getName())
                .description(combo.getDescription())
                .price(combo.getPrice())
                .imageUrl(combo.getImageUrl())
                .available(combo.isAvailable())
                .active(combo.isActive())
                .position(combo.getPosition() != null ? combo.getPosition() : 0)
                .items(combo.getComboItems().stream()
                        .map(i -> new Item(i.getProduct().getId(), i.getProduct().getName(), i.getQuantity()))
                        .toList())
                .originalPrice(original)
                .savings(original.subtract(combo.getPrice()).max(BigDecimal.ZERO))
                .build();
    }
}
