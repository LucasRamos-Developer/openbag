package com.openbag.modules.delivery.dto;

import com.openbag.enums.CourierPolicy;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Regras de entrega do restaurante: quem recebe os pedidos, parceiros e se ele cobre a diferença da tabela
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RestaurantDeliverySettingsDTO {

    private CourierPolicy courierPolicy;
    private boolean fallbackToOpen;
    private boolean coversDeliveryDifference;
    private LocalDateTime coversDeliveryDifferenceAcceptedAt;
    private BigDecimal deliveryFee;
    private List<PartnerDTO> partners;
    private long activeFixedCouriers;
    private long pendingFixedCouriers;
    private int courierNoShowMinutes;
}
