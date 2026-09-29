package com.openbag.restaurant.store.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Restaurante resumido para o seletor do painel do dono
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class RestaurantSummaryDTO {
    private Long id;
    private String name;
    private String slug;
    private String logoUrl;
    private boolean active;
    private boolean openNow;
}
