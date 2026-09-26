package com.openbag.modules.organization.dto;

import com.openbag.enums.MembershipOrigin;
import com.openbag.enums.MembershipStatus;
import com.openbag.enums.VehicleType;
import com.openbag.modules.delivery.entity.DeliveryPerson;
import com.openbag.modules.organization.entity.AssociationMembership;
import com.openbag.modules.user.entity.User;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Associado: vínculo + dados do entregador e da conta
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MemberDTO {

    private Long membershipId;
    private MembershipStatus status;
    private MembershipOrigin origin;
    private Integer memberNumber;
    private LocalDateTime requestedAt;
    private LocalDateTime decidedAt;
    private LocalDateTime endedAt;
    private String reason;

    private Long organizationId;
    private String organizationName;

    private Long deliveryPersonId;
    private Long userId;
    private String fullName;
    private String email;
    private String phoneNumber;
    private String profileImageUrl;
    private String documentNumber;
    private String driverLicense;
    private VehicleType vehicleType;
    private String vehiclePlate;
    private String vehicleModel;
    private String vehicleColor;
    private boolean available;
    private BigDecimal rating;
    private Integer totalDeliveries;

    public static MemberDTO from(AssociationMembership membership) {
        DeliveryPerson deliveryPerson = membership.getDeliveryPerson();
        User user = deliveryPerson.getUser();
        return MemberDTO.builder()
                .membershipId(membership.getId())
                .status(membership.getStatus())
                .origin(membership.getOrigin())
                .memberNumber(membership.getMemberNumber())
                .requestedAt(membership.getRequestedAt())
                .decidedAt(membership.getDecidedAt())
                .endedAt(membership.getEndedAt())
                .reason(membership.getReason())
                .organizationId(membership.getOrganization().getId())
                .organizationName(membership.getOrganization().getTradingName())
                .deliveryPersonId(deliveryPerson.getId())
                .userId(user.getId())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .phoneNumber(user.getPhoneNumber())
                .profileImageUrl(user.getProfileImageUrl())
                .documentNumber(deliveryPerson.getDocumentNumber())
                .driverLicense(deliveryPerson.getDriverLicense())
                .vehicleType(deliveryPerson.getVehicleType())
                .vehiclePlate(deliveryPerson.getVehiclePlate())
                .vehicleModel(deliveryPerson.getVehicleModel())
                .vehicleColor(deliveryPerson.getVehicleColor())
                .available(deliveryPerson.isAvailable())
                .rating(deliveryPerson.getRating())
                .totalDeliveries(deliveryPerson.getTotalDeliveries())
                .build();
    }
}
