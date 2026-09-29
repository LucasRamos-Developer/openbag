package com.openbag.modules.delivery.dto;

import com.openbag.enums.OrderStatus;
import com.openbag.order.core.entity.Order;
import com.openbag.order.core.entity.OrderItem;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Entrega vista pelo entregador: onde retirar, onde entregar, quanto cobrar e quanto ele recebe
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CourierOrderDTO {

    private Long orderId;
    private String displayCode;
    private OrderStatus status;
    private CourierLinkDTO.RestaurantInfo restaurant;
    private String restaurantPhone;
    private String customerName;
    private String customerPhone;
    private String deliveryAddress;
    private Double deliveryLatitude;
    private Double deliveryLongitude;
    private List<String> items;
    private String notes;
    private Order.PaymentMethod paymentMethod;
    private BigDecimal totalAmount;
    private BigDecimal changeFor;
    private BigDecimal courierFee;
    private Double deliveryDistanceKm;
    private LocalDateTime assignedAt;
    private LocalDateTime readyAt;
    private LocalDateTime pickedUpAt;
    private LocalDateTime deliveredAt;
    // Em rota: qual rota e a posição desta entrega (1 = primeira)
    private Long routeId;
    private Integer routeSequence;
    private String neighborhood;

    public static CourierOrderDTO from(Order order) {
        return CourierOrderDTO.builder()
                .orderId(order.getId())
                .displayCode(order.getDisplayCode())
                .status(order.getStatus())
                .restaurant(CourierLinkDTO.restaurantInfo(order.getRestaurant()))
                .restaurantPhone(order.getRestaurant().getPhoneNumber())
                .customerName(order.getCustomerName())
                .customerPhone(order.getCustomerPhone())
                .deliveryAddress(order.getDeliveryAddress())
                .deliveryLatitude(order.getDeliveryLatitude())
                .deliveryLongitude(order.getDeliveryLongitude())
                .items(order.getItems().stream().map(CourierOrderDTO::itemLine).toList())
                .notes(order.getOrderNotes())
                .paymentMethod(order.getPaymentMethod())
                .totalAmount(order.getTotalAmount())
                .changeFor(order.getChangeFor())
                .courierFee(order.getCourierFee())
                .deliveryDistanceKm(order.getDeliveryDistanceKm())
                .assignedAt(order.getAssignedAt())
                .readyAt(order.getReadyAt())
                .pickedUpAt(order.getPickedUpAt())
                .deliveredAt(order.getDeliveredAt())
                .routeId(order.getRoute() != null ? order.getRoute().getId() : null)
                .routeSequence(order.getRouteSequence())
                .neighborhood(order.getDeliveryNeighborhood())
                .build();
    }

    private static String itemLine(OrderItem item) {
        return item.getQuantity() + "x " + item.getItemName();
    }
}
