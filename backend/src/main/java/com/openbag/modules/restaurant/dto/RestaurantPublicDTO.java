package com.openbag.modules.restaurant.dto;

import com.openbag.enums.RestaurantThemePreset;
import com.openbag.modules.order.entity.Order;
import com.openbag.modules.product.entity.Category;
import com.openbag.modules.restaurant.entity.LayoutConfig;
import com.openbag.modules.restaurant.entity.OpeningHour;
import com.openbag.modules.restaurant.entity.Restaurant;
import com.openbag.modules.user.entity.Address;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;

/**
 * Página pública do restaurante (sem dados do dono)
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RestaurantPublicDTO {

    /** Formas de pagamento aceitas na entrega (MVP: sem pagamento online) */
    public static final List<Order.PaymentMethod> PAYMENT_METHODS = List.of(
            Order.PaymentMethod.PIX, Order.PaymentMethod.CREDIT_CARD, Order.PaymentMethod.DEBIT_CARD,
            Order.PaymentMethod.CASH, Order.PaymentMethod.FOOD_VOUCHER);

    private Long id;
    private String name;
    private String slug;
    private String description;
    private String phoneNumber;
    private String cnpj;
    private String logoUrl;
    private String bannerUrl;
    /** Cor principal efetiva (cor da marca ou a do tema) */
    private String primaryColor;
    private RestaurantThemePreset themePreset;
    private String brandColor;
    private String slogan;
    private BigDecimal rating;
    private Integer totalReviews;
    private BigDecimal deliveryFee;
    private BigDecimal minimumOrder;
    private Integer deliveryTimeMin;
    private Integer deliveryTimeMax;
    private String priceRange;

    private boolean openNow;
    private LocalDateTime pausedUntil;

    private List<String> categories;
    private PublicAddress address;
    private List<OpeningHourDTO> openingHours;
    private List<Order.PaymentMethod> paymentMethods;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PublicAddress {
        private String street;
        private String number;
        private String complement;
        private String neighborhood;
        private String city;
        private String state;
        private String zipCode;
        private Double latitude;
        private Double longitude;
    }

    public static RestaurantPublicDTO from(Restaurant restaurant, LocalDateTime now) {
        Address address = restaurant.getAddress();
        LayoutConfig layout = restaurant.getLayoutConfig();
        return RestaurantPublicDTO.builder()
                .id(restaurant.getId())
                .name(restaurant.getName())
                .slug(restaurant.getSlug())
                .description(restaurant.getDescription())
                .phoneNumber(restaurant.getPhoneNumber())
                .cnpj(restaurant.getCnpj())
                .logoUrl(restaurant.getLogoUrl())
                .bannerUrl(restaurant.getBannerUrl())
                .primaryColor(layout != null ? layout.getEffectivePrimaryColor() : RestaurantThemePreset.DEFAULT.getPrimaryHex())
                .themePreset(layout != null ? layout.getThemePreset() : RestaurantThemePreset.DEFAULT)
                .brandColor(layout != null ? layout.getBrandColor() : null)
                .slogan(layout != null ? layout.getSlogan() : null)
                .rating(restaurant.getRating())
                .totalReviews(restaurant.getTotalReviews())
                .deliveryFee(restaurant.getDeliveryFee())
                .minimumOrder(restaurant.getMinimumOrder())
                .deliveryTimeMin(restaurant.getDeliveryTimeMin())
                .deliveryTimeMax(restaurant.getDeliveryTimeMax())
                .priceRange(restaurant.getPriceRange())
                .openNow(restaurant.isOpenNow(now))
                .pausedUntil(restaurant.isPaused(now) ? restaurant.getPausedUntil() : null)
                .categories(restaurant.getCategories().stream().map(Category::getName).toList())
                .address(address == null ? null : new PublicAddress(address.getStreet(), address.getNumber(),
                        address.getComplement(), address.getNeighborhood(), address.getCity(), address.getState(),
                        address.getZipCode(),
                        address.getLatitude() != null ? address.getLatitude()
                                : restaurant.getLatitude() != null ? restaurant.getLatitude().doubleValue() : null,
                        address.getLongitude() != null ? address.getLongitude()
                                : restaurant.getLongitude() != null ? restaurant.getLongitude().doubleValue() : null))
                .openingHours(restaurant.getOpeningHours().stream()
                        .sorted(Comparator.comparing(OpeningHour::getWeekday).thenComparing(OpeningHour::getOpenTime))
                        .map(h -> new OpeningHourDTO(h.getLabel(), h.getWeekday(), h.getOpenTime(), h.getCloseTime(), h.getObservation()))
                        .toList())
                .paymentMethods(PAYMENT_METHODS)
                .build();
    }
}
