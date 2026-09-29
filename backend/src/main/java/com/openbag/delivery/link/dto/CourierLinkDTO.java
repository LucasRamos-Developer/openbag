package com.openbag.delivery.link.dto;

import com.openbag.delivery.link.entity.CourierLinkStatus;
import com.openbag.delivery.link.entity.LinkRequester;
import com.openbag.delivery.courier.entity.DeliveryPerson;
import com.openbag.delivery.link.entity.RestaurantCourierLink;
import com.openbag.restaurant.store.entity.Restaurant;
import com.openbag.account.entity.Address;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import com.openbag.delivery.courier.dto.VehicleDTO;

/**
 * Vínculo de entregador fixo, visto pelo restaurante (dados do entregador) ou pelo entregador (dados do restaurante)
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CourierLinkDTO {

    private Long id;
    private CourierLinkStatus status;
    private LinkRequester requestedBy;
    private LocalDateTime createdAt;
    private LocalDateTime decidedAt;
    private LocalDateTime endedAt;
    private RestaurantInfo restaurant;
    private CourierInfo courier;
    // Em check-in neste restaurante agora (turno fixo aberto)
    private boolean checkedIn;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RestaurantInfo {
        private Long id;
        private String name;
        private String slug;
        private String logoUrl;
        private String address;
        private Double latitude;
        private Double longitude;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CourierInfo {
        private Long deliveryPersonId;
        private String fullName;
        private String photoUrl;
        private String slug;
        private String phoneNumber;
        private String associationName;
        private VehicleDTO vehicle;
    }

    public static CourierLinkDTO from(RestaurantCourierLink link, boolean checkedIn) {
        return CourierLinkDTO.builder()
                .id(link.getId())
                .status(link.getStatus())
                .requestedBy(link.getRequestedBy())
                .createdAt(link.getCreatedAt())
                .decidedAt(link.getDecidedAt())
                .endedAt(link.getEndedAt())
                .restaurant(restaurantInfo(link.getRestaurant()))
                .courier(courierInfo(link.getDeliveryPerson()))
                .checkedIn(checkedIn)
                .build();
    }

    public static RestaurantInfo restaurantInfo(Restaurant restaurant) {
        Address address = restaurant.getAddress();
        String line = address == null ? null
                : String.join(", ", java.util.stream.Stream.of(
                                address.getStreet() != null && address.getNumber() != null
                                        ? address.getStreet() + ", " + address.getNumber() : address.getStreet(),
                                address.getNeighborhood(), address.getCity())
                        .filter(java.util.Objects::nonNull).toList());
        return RestaurantInfo.builder()
                .id(restaurant.getId())
                .name(restaurant.getName())
                .slug(restaurant.getSlug())
                .logoUrl(restaurant.getLogoUrl())
                .address(line)
                .latitude(restaurant.getLatitude() != null ? restaurant.getLatitude().doubleValue() : null)
                .longitude(restaurant.getLongitude() != null ? restaurant.getLongitude().doubleValue() : null)
                .build();
    }

    public static CourierInfo courierInfo(DeliveryPerson deliveryPerson) {
        return CourierInfo.builder()
                .deliveryPersonId(deliveryPerson.getId())
                .fullName(deliveryPerson.getUser().getFullName())
                .photoUrl(deliveryPerson.getPhotoUrl())
                .slug(deliveryPerson.getSlug())
                .phoneNumber(deliveryPerson.getUser().getPhoneNumber())
                .associationName(deliveryPerson.getOrganization() != null
                        ? deliveryPerson.getOrganization().getTradingName() : null)
                .vehicle(deliveryPerson.getActiveVehicle() != null
                        ? VehicleDTO.from(deliveryPerson.getActiveVehicle(), true) : null)
                .build();
    }
}
