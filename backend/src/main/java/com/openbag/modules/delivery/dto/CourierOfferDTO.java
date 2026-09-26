package com.openbag.modules.delivery.dto;

import com.openbag.modules.delivery.entity.DeliveryOffer;
import com.openbag.modules.order.entity.Order;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Oferta de entrega mostrada ao entregador, com contagem regressiva até {@code expiresAt}
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CourierOfferDTO {

    private Long offerId;
    private Long orderId;
    private String displayCode;
    private CourierLinkDTO.RestaurantInfo restaurant;
    private String deliveryAddress;
    private Double pickupDistanceKm;
    private Double deliveryDistanceKm;
    private BigDecimal courierFee;
    private Order.PaymentMethod paymentMethod;
    private BigDecimal totalAmount;
    private LocalDateTime offeredAt;
    private LocalDateTime expiresAt;
    // Segundos restantes no momento da resposta (evita depender do relógio do aparelho)
    private long secondsLeft;

    public static CourierOfferDTO from(DeliveryOffer offer, LocalDateTime now) {
        Order order = offer.getOrder();
        return CourierOfferDTO.builder()
                .offerId(offer.getId())
                .orderId(order.getId())
                .displayCode(order.getDisplayCode())
                .restaurant(CourierLinkDTO.restaurantInfo(order.getRestaurant()))
                .deliveryAddress(order.getDeliveryAddress())
                .pickupDistanceKm(offer.getPickupDistanceKm())
                .deliveryDistanceKm(offer.getDeliveryDistanceKm())
                .courierFee(offer.getCourierFee())
                .paymentMethod(order.getPaymentMethod())
                .totalAmount(order.getTotalAmount())
                .offeredAt(offer.getOfferedAt())
                .expiresAt(offer.getExpiresAt())
                .secondsLeft(Math.max(0, java.time.Duration.between(now, offer.getExpiresAt()).getSeconds()))
                .build();
    }
}
