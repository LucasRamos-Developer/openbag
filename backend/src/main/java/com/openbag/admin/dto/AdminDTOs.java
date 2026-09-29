package com.openbag.admin.dto;

import com.openbag.delivery.courier.entity.CourierWorkStatus;
import com.openbag.order.core.entity.OrderStatus;
import com.openbag.delivery.courier.entity.DeliveryPerson;
import com.openbag.delivery.courier.entity.Vehicle;
import com.openbag.order.core.entity.Order;
import com.openbag.restaurant.store.entity.Restaurant;
import com.openbag.account.entity.Role;
import com.openbag.account.entity.User;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Visões somente leitura do painel admin. Nunca expõem entidades, senha ou documentos (CPF/CNH).
 */
public final class AdminDTOs {

    private AdminDTOs() {
    }

    /** Números da plataforma na visão geral */
    public record Overview(
            long restaurants,
            long restaurantsOpenNow,
            long associations,
            long associationsPending,
            long couriers,
            long couriersOnline,
            long users,
            long ordersToday) {
    }

    public record RestaurantRow(
            Long id,
            String name,
            String slug,
            String ownerName,
            String ownerEmail,
            String city,
            boolean active,
            boolean openNow,
            LocalDateTime createdAt) {

        public static RestaurantRow from(Restaurant restaurant, LocalDateTime now) {
            User owner = restaurant.getOwner();
            return new RestaurantRow(
                    restaurant.getId(),
                    restaurant.getName(),
                    restaurant.getSlug(),
                    owner != null ? owner.getFullName() : null,
                    owner != null ? owner.getEmail() : null,
                    restaurant.getAddress() != null ? restaurant.getAddress().getCity() : null,
                    restaurant.isActive(),
                    restaurant.isOpenNow(now),
                    restaurant.getCreatedAt());
        }
    }

    public record CourierRow(
            Long id,
            String fullName,
            String email,
            String slug,
            String association,
            String vehicle,
            CourierWorkStatus workStatus,
            boolean active,
            Integer totalDeliveries,
            BigDecimal rating) {

        public static CourierRow from(DeliveryPerson courier) {
            Vehicle vehicle = courier.getActiveVehicle();
            String vehicleLabel = vehicle == null ? null
                    : vehicle.getType().getDisplayName() + (vehicle.getPlate() != null ? " · " + vehicle.getPlate() : "");
            return new CourierRow(
                    courier.getId(),
                    courier.getUser().getFullName(),
                    courier.getUser().getEmail(),
                    courier.getSlug(),
                    courier.getOrganization() != null ? courier.getOrganization().getTradingName() : null,
                    vehicleLabel,
                    courier.getWorkStatus() != null ? courier.getWorkStatus() : CourierWorkStatus.OFFLINE,
                    courier.isActive(),
                    courier.getTotalDeliveries(),
                    courier.getRating());
        }
    }

    public record UserRow(
            Long id,
            String fullName,
            String email,
            String phoneNumber,
            List<String> roles,
            boolean active,
            LocalDateTime createdAt) {

        public static UserRow from(User user) {
            return new UserRow(
                    user.getId(),
                    user.getFullName(),
                    user.getEmail(),
                    user.getPhoneNumber(),
                    user.getRoles().stream().map(Role::getName).sorted().toList(),
                    user.isActive(),
                    user.getCreatedAt());
        }
    }

    public record OrderRow(
            Long id,
            String displayCode,
            String restaurantName,
            String restaurantSlug,
            String customerName,
            String courierName,
            OrderStatus status,
            BigDecimal totalAmount,
            LocalDateTime createdAt) {

        public static OrderRow from(Order order) {
            String customer = order.getCustomerName() != null ? order.getCustomerName()
                    : order.getUser() != null ? order.getUser().getFullName() : null;
            return new OrderRow(
                    order.getId(),
                    order.getDisplayCode() != null ? order.getDisplayCode() : order.getOrderNumber(),
                    order.getRestaurant().getName(),
                    order.getRestaurant().getSlug(),
                    customer,
                    order.getDeliveryPerson() != null ? order.getDeliveryPerson().getUser().getFullName() : null,
                    order.getStatus(),
                    order.getTotalAmount(),
                    order.getCreatedAt());
        }
    }
}
