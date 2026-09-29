package com.openbag.delivery.courier.dto;

import com.openbag.enums.VehicleType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Perfil público do entregador (/e/{slug}), aberto pelo QR code da placa de verificação
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CourierPublicDTO {

    private String slug;
    private String fullName;
    private String photoUrl;
    private String bio;
    private List<SocialLinkDTO> socialLinks;
    private LocalDateTime memberSince;
    private BigDecimal rating;
    private Integer totalReviews;
    private Integer totalDeliveries;
    private CourierAssociationDTO association;
    private PublicVehicle vehicle;
    // Só quando o entregador permite (showWorkHistory)
    private List<WorkHistoryDTO.RestaurantEntry> workHistory;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PublicVehicle {
        private VehicleType type;
        private String model;
        private String color;
        // Só o começo e o fim da placa, para conferência sem expor o dado inteiro
        private String maskedPlate;
    }
}
