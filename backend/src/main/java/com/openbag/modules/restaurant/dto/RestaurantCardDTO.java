package com.openbag.modules.restaurant.dto;

import com.openbag.modules.product.entity.Category;
import com.openbag.modules.restaurant.entity.Restaurant;
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
    private BigDecimal rating;
    private Integer totalReviews;
    private BigDecimal deliveryFee;
    private BigDecimal minimumOrder;
    private Integer deliveryTimeMin;
    private Integer deliveryTimeMax;
    private boolean openNow;
    private List<String> categories;

    public static RestaurantCardDTO from(Restaurant restaurant, LocalDateTime now) {
        return RestaurantCardDTO.builder()
                .id(restaurant.getId())
                .name(restaurant.getName())
                .slug(restaurant.getSlug())
                .logoUrl(restaurant.getLogoUrl())
                .bannerUrl(restaurant.getBannerUrl())
                .rating(restaurant.getRating())
                .totalReviews(restaurant.getTotalReviews())
                .deliveryFee(restaurant.getDeliveryFee())
                .minimumOrder(restaurant.getMinimumOrder())
                .deliveryTimeMin(restaurant.getDeliveryTimeMin())
                .deliveryTimeMax(restaurant.getDeliveryTimeMax())
                .openNow(restaurant.isOpenNow(now))
                .categories(restaurant.getCategories().stream().map(Category::getName).toList())
                .build();
    }
}
