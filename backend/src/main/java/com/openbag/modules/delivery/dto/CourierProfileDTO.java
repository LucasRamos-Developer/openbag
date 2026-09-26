package com.openbag.modules.delivery.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Perfil do entregador logado (painel)
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CourierProfileDTO {

    private Long id;
    private String slug;
    private String fullName;
    private String email;
    private String phoneNumber;
    private String photoUrl;
    private String bio;
    private boolean showWorkHistory;
    private List<SocialLinkDTO> socialLinks;
    private VehicleDTO activeVehicle;
    private BigDecimal rating;
    private Integer totalDeliveries;
    private LocalDateTime memberSince;
    // null quando não há vínculo aberto
    private CourierAssociationDTO association;
}
