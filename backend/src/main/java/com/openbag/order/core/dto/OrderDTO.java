package com.openbag.order.core.dto;

import com.openbag.modules.delivery.dispatch.ReassignPolicy;
import com.openbag.enums.CancelledBy;
import com.openbag.enums.FulfillmentType;
import com.openbag.enums.OrderChannel;
import com.openbag.enums.OrderStatus;
import com.openbag.enums.VehicleType;
import com.openbag.modules.delivery.entity.DeliveryPerson;
import com.openbag.modules.delivery.entity.Vehicle;
import com.openbag.order.core.entity.Order;
import com.openbag.order.core.entity.OrderItem;
import com.openbag.order.core.entity.OrderTracking;
import com.openbag.order.core.entity.OrderItemCustomization;
import com.openbag.restaurant.store.entity.Restaurant;
import com.openbag.order.review.dto.OrderReviewDTO;
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

    // Por onde chegou (app, balcão, telefone, WhatsApp) e se é entrega ou retirada na loja
    private OrderChannel channel;
    private FulfillmentType fulfillment;

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
    // FIXED, FREE ou STAFF (quem está com o pedido); a equipe própria vem em staffCourier
    private ReassignPolicy.CourierKind courierKind;
    private StaffInfo staffCourier;
    // Entregador livre: a partir de quando a loja pode trocá-lo se ele não aparecer
    private LocalDateTime reassignableAt;
    private LocalDateTime assignedAt;
    private LocalDateTime pickedUpAt;
    // Aceito e ainda sem entregador disponível desde este momento
    private LocalDateTime searchingCourierSince;

    // Só para o cliente (CustomerOrderMapper): posição do entregador quando é a vez do pedido,
    // a avaliação feita e até quando ainda dá para avaliar
    private Location courierLocation;
    private OrderReviewDTO review;
    private LocalDateTime reviewableUntil;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RestaurantInfo {
        private Long id;
        private String name;
        private String slug;
        private String logoUrl;
        private String phoneNumber;
        private Double latitude;
        private Double longitude;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Location {
        private double latitude;
        private double longitude;
        private LocalDateTime at;
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

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class StaffInfo {
        private Long id;
        private String name;
        private String phone;
    }

    public static OrderDTO from(Order order) {
        Restaurant restaurant = order.getRestaurant();
        return OrderDTO.builder()
                .id(order.getId())
                .orderNumber(order.getOrderNumber())
                .displayCode(order.getDisplayCode())
                .status(order.getStatus())
                .channel(order.channelOrDefault())
                .fulfillment(order.fulfillmentOrDefault())
                .restaurant(new RestaurantInfo(restaurant.getId(), restaurant.getName(), restaurant.getSlug(),
                        restaurant.getLogoUrl(), restaurant.getPhoneNumber(), toDouble(restaurant.getLatitude()),
                        toDouble(restaurant.getLongitude())))
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
                .courierKind(ReassignPolicy.kindOf(order))
                .staffCourier(order.getStaffCourier() == null ? null : new StaffInfo(order.getStaffCourier().getId(),
                        order.getStaffCourier().getName(), order.getStaffCourier().getPhone()))
                .reassignableAt(ReassignPolicy.availableAt(order))
                .assignedAt(order.getAssignedAt())
                .pickedUpAt(order.getPickedUpAt())
                .searchingCourierSince(order.getDeliveryPerson() == null && order.getStaffCourier() == null
                        ? order.getSearchingCourierSince() : null)
                .build();
    }

    /**
     * Versão para o cliente: sem dados da operação da loja (tipo de entregador, prazo de troca). O cliente nunca
     * fica sabendo de rotas ou de espera por outros pedidos. A posição do entregador e a avaliação são
     * preenchidas pelo {@code CustomerOrderMapper}.
     */
    public static OrderDTO forCustomer(Order order) {
        OrderDTO dto = from(order);
        dto.setCourierKind(null);
        dto.setReassignableAt(null);
        return dto;
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

    private static Double toDouble(BigDecimal value) {
        return value == null ? null : value.doubleValue();
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
