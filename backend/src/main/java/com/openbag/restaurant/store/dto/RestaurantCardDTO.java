package com.openbag.restaurant.store.dto;

import com.openbag.restaurant.store.entity.DeliveryFeeMode;
import com.openbag.restaurant.catalog.entity.Category;
import com.openbag.restaurant.store.entity.RestaurantThemePreset;
import com.openbag.restaurant.store.entity.LayoutConfig;
import com.openbag.restaurant.store.entity.Restaurant;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Restaurante nas listagens (home, busca, categorias)
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RestaurantCardDTO {

    private Long id;
    private String name;
    private String slug;
    private String logoUrl;
    private String bannerUrl;
    /** Cores escolhidas pela loja: o card da vitrine usa na imagem de fundo e no logo */
    private RestaurantThemePreset themePreset;
    private String brandColor;
    /** Cor principal efetiva (cor da marca ou a do tema) */
    private String primaryColor;
    private BigDecimal rating;
    private Integer totalReviews;
    /** Taxa fixa ou, se a loja repassa a taxa ao cliente, o valor "a partir de" (ver {@link #deliveryFeeMode}) */
    private BigDecimal deliveryFee;
    private DeliveryFeeMode deliveryFeeMode;
    private BigDecimal minimumOrder;
    private Integer deliveryTimeMin;
    private Integer deliveryTimeMax;
    private boolean openNow;
    private LocalDateTime pausedUntil;
    /** Quando fecha (se aberto e com horários) */
    private LocalDateTime closesAt;
    /** Próxima abertura (se fechado por horário ou pausa) */
    private LocalDateTime nextOpenAt;
    private List<String> categories;
    private RestaurantPublicDTO.PublicAddress address;

    public static RestaurantCardDTO from(Restaurant restaurant, LocalDateTime now) {
        LayoutConfig layout = restaurant.getLayoutConfig();
        return RestaurantCardDTO.builder()
                .id(restaurant.getId())
                .name(restaurant.getName())
                .slug(restaurant.getSlug())
                .logoUrl(restaurant.getLogoUrl())
                .bannerUrl(restaurant.getBannerUrl())
                .themePreset(layout != null ? layout.getThemePreset() : RestaurantThemePreset.DEFAULT)
                .brandColor(layout != null ? layout.getBrandColor() : null)
                .primaryColor(layout != null ? layout.getEffectivePrimaryColor() : RestaurantThemePreset.DEFAULT.getPrimaryHex())
                .rating(restaurant.getRating())
                .totalReviews(restaurant.getTotalReviews())
                .deliveryFee(restaurant.getDeliveryFee())
                .deliveryFeeMode(restaurant.getDeliveryFeeMode())
                .minimumOrder(restaurant.getMinimumOrder())
                .deliveryTimeMin(restaurant.getDeliveryTimeMin())
                .deliveryTimeMax(restaurant.getDeliveryTimeMax())
                .openNow(restaurant.isOpenNow(now))
                .pausedUntil(restaurant.isPaused(now) ? restaurant.getPausedUntil() : null)
                .closesAt(restaurant.closesAt(now))
                .nextOpenAt(restaurant.nextOpeningAt(now))
                .address(RestaurantPublicDTO.PublicAddress.from(restaurant))
                .categories(restaurant.getCategories().stream().map(Category::getName).toList())
                .build();
    }
}
