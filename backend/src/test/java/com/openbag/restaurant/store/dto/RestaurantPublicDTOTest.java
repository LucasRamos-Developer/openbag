package com.openbag.restaurant.store.dto;

import com.openbag.enums.RestaurantThemePreset;
import com.openbag.restaurant.store.entity.LayoutConfig;
import com.openbag.restaurant.store.entity.Restaurant;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;

class RestaurantPublicDTOTest {

    private static final LocalDateTime NOW = LocalDateTime.of(2026, 9, 21, 12, 0);

    private Restaurant restaurant(LayoutConfig layout) {
        Restaurant restaurant = new Restaurant();
        restaurant.setId(1L);
        restaurant.setName("Burger da Vila");
        restaurant.setLayoutConfig(layout);
        return restaurant;
    }

    @Test
    void withoutLayoutUsesDefaultTheme() {
        RestaurantPublicDTO dto = RestaurantPublicDTO.from(restaurant(null), NOW);

        assertThat(dto.getThemePreset()).isEqualTo(RestaurantThemePreset.FRESH_GREEN);
        assertThat(dto.getPrimaryColor()).isEqualTo("#00A878");
        assertThat(dto.getBrandColor()).isNull();
    }

    @Test
    void legacyLayoutWithoutThemeUsesDefaultTheme() {
        LayoutConfig legacy = new LayoutConfig();
        legacy.setPrimaryColor("#FF0000");
        legacy.setSecondaryColor("#000000");

        RestaurantPublicDTO dto = RestaurantPublicDTO.from(restaurant(legacy), NOW);

        assertThat(dto.getThemePreset()).isEqualTo(RestaurantThemePreset.FRESH_GREEN);
        assertThat(dto.getPrimaryColor()).isEqualTo("#00A878");
    }

    @Test
    void brandColorWinsOverThemeColor() {
        LayoutConfig layout = new LayoutConfig();
        layout.applyAppearance(RestaurantThemePreset.GRAPHITE, "#aa00aa", "Desde 1990");

        RestaurantPublicDTO dto = RestaurantPublicDTO.from(restaurant(layout), NOW);

        assertThat(dto.getThemePreset()).isEqualTo(RestaurantThemePreset.GRAPHITE);
        assertThat(dto.getPrimaryColor()).isEqualTo("#AA00AA");
        assertThat(dto.getSlogan()).isEqualTo("Desde 1990");
    }
}
