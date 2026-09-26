package com.openbag.modules.order.dto;

import com.openbag.enums.CancelledBy;
import com.openbag.enums.OrderStatus;
import com.openbag.enums.VehicleType;
import com.openbag.modules.delivery.entity.DeliveryPerson;
import com.openbag.modules.delivery.entity.Vehicle;
import com.openbag.modules.order.entity.Order;
import com.openbag.modules.order.entity.OrderItem;
import com.openbag.modules.order.entity.OrderTracking;
import com.openbag.modules.product.entity.OrderItemCustomization;
import com.openbag.modules.restaurant.entity.Restaurant;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;

/**
 * Pedido para o cliente, o restaurante e a cozinha
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OrderDTO {

    private Long id;
    private String orderNumber;
    private String displayCode;
    private OrderStatus status;

    private RestaurantInfo restaurant;
    private String customerName;
    private String customerPhone;

    private List<Item> items;
    private BigDecimal subtotal;
    private BigDecimal deliveryFee;
    private BigDecimal totalAmount;

    private Order.PaymentMethod paymentMethod;
    private BigDecimal changeFor;
    private String deliveryAddress;
    private Double deliveryLatitude;
    private Double deliveryLongitude;
    private String notes;

    // Tempo máximo de entrega informado ao cliente (minutos)
    private Integer estimatedDeliveryTime;

    private LocalDateTime createdAt;
    private LocalDateTime acceptDeadline;
    private LocalDateTime acceptedAt;
    private LocalDateTime readyAt;
    private LocalDateTime dispatchedAt;
    private LocalDateTime deliveredAt;
    private LocalDateTime cancelledAt;
    private CancelledBy cancelledBy;
    private String cancellationReason;

    private List<TimelineEntry> timeline;

    // Entrega pelo entregador do app
    private CourierInfo courier;
    private LocalDateTime assignedAt;
    private LocalDateTime pickedUpAt;
    // Aceito e ainda sem entregador disponível desde este momento
    private LocalDateTime searchingCourierSince;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RestaurantInfo {
        private Long id;
        private String name;
        private String slug;
        private String logoUrl;
        private String phoneNumber;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Item {
        private Long productId;
        private Long comboId;
        private String name;
        private int quantity;
        private BigDecimal unitPrice;
        private BigDecimal totalPrice;
        private String notes;
        private List<Customization> customizations;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Customization {
        private String groupName;
        private String optionName;
        private BigDecimal price;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class TimelineEntry {
        private OrderStatus status;
        private String message;
        private LocalDateTime at;
    }

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    public static class CourierInfo {
        private Long deliveryPersonId;
        private String fullName;
        private String photoUrl;
        private String slug;
        private String phoneNumber;
        private VehicleType vehicleType;
        private String vehicleDescription;
        private String vehiclePlate;
    }

    public static OrderDTO from(Order order) {
        Restaurant restaurant = order.getRestaurant();
        return OrderDTO.builder()
                .id(order.getId())
                .orderNumber(order.getOrderNumber())
                .displayCode(order.getDisplayCode())
                .status(order.getStatus())
                .restaurant(new RestaurantInfo(restaurant.getId(), restaurant.getName(), restaurant.getSlug(),
                        restaurant.getLogoUrl(), restaurant.getPhoneNumber()))
                .customerName(order.getCustomerName())
                .customerPhone(order.getCustomerPhone())
                .items(order.getItems().stream().map(OrderDTO::toItem).toList())
                .subtotal(order.getSubtotal())
                .deliveryFee(order.getDeliveryFee())
                .totalAmount(order.getTotalAmount())
                .paymentMethod(order.getPaymentMethod())
                .changeFor(order.getChangeFor())
                .deliveryAddress(order.getDeliveryAddress())
                .deliveryLatitude(order.getDeliveryLatitude())
                .deliveryLongitude(order.getDeliveryLongitude())
                .notes(order.getOrderNotes())
                .estimatedDeliveryTime(order.getEstimatedDeliveryTime())
                .createdAt(order.getOrderDate())
                .acceptDeadline(order.getAcceptDeadline())
                .acceptedAt(order.getAcceptedAt())
                .readyAt(order.getReadyAt())
                .dispatchedAt(order.getDispatchedAt())
                .deliveredAt(order.getDeliveredAt())
                .cancelledAt(order.getCancelledAt())
                .cancelledBy(order.getCancelledBy())
                .cancellationReason(order.getCancellationReason())
                .timeline(order.getTrackings().stream()
                        .sorted(Comparator.comparing(OrderTracking::getTimestamp, Comparator.nullsLast(Comparator.naturalOrder())))
                        .map(t -> new TimelineEntry(t.getStatus(), t.getMessage(), t.getTimestamp()))
                        .toList())
                .courier(toCourier(order.getDeliveryPerson()))
                .assignedAt(order.getAssignedAt())
                .pickedUpAt(order.getPickedUpAt())
                .searchingCourierSince(order.getDeliveryPerson() == null ? order.getSearchingCourierSince() : null)
                .build();
    }

    private static CourierInfo toCourier(DeliveryPerson courier) {
        if (courier == null) {
            return null;
        }
        Vehicle vehicle = courier.getActiveVehicle();
        String description = vehicle == null ? null
                : String.join(" · ", java.util.stream.Stream.of(vehicle.getModel(), vehicle.getColor())
                .filter(java.util.Objects::nonNull).toList());
        return new CourierInfo(courier.getId(), courier.getUser().getFullName(), courier.getPhotoUrl(),
                courier.getSlug(), courier.getUser().getPhoneNumber(),
                vehicle != null ? vehicle.getType() : null, description, vehicle != null ? vehicle.getPlate() : null);
    }

    private static Item toItem(OrderItem item) {
        return new Item(
                item.getProduct() != null ? item.getProduct().getId() : null,
                item.getCombo() != null ? item.getCombo().getId() : null,
                item.getItemName(),
                item.getQuantity(),
                item.getUnitPrice(),
                item.getTotalPrice(),
                item.getObservations(),
                item.getCustomizations().stream()
                        .map((OrderItemCustomization c) -> new Customization(c.getGroupName(), c.getOptionName(), c.getPriceAtPurchase()))
                        .toList());
    }
}
