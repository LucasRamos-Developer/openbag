package com.openbag.delivery.dispatch.dto;

import com.openbag.restaurant.store.entity.CourierPolicy;
import com.openbag.restaurant.store.entity.DeliveryFeeMode;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import com.openbag.association.partnership.dto.PartnerDTO;

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
    private DeliveryFeeMode deliveryFeeMode;
    // Se repassar: o "a partir de" e quanto o cliente pagaria em algumas distâncias (a maior tabela)
    private BigDecimal deliveryFeeFrom;
    private List<FeeSample> deliveryFeeSimulation;
    // Parcerias ativas
    private List<PartnerDTO> partners;
    // Pedidos de parceria pendentes (enviados pela loja ou convites das associações)
    private List<PartnerDTO> partnershipRequests;
    // Recusadas ou encerradas, mais recentes primeiro
    private List<PartnerDTO> partnershipHistory;
    // Pedidos e propostas de tabela que esperam a resposta da loja
    private long pendingPartnershipActions;
    // A associação encerrou a última parceria e a loja passou a receber de qualquer entregador
    private LocalDateTime partnersEndedNoticeAt;
    private long activeFixedCouriers;
    private long pendingFixedCouriers;
    private int courierNoShowMinutes;
    private boolean requireDeliveryPin;

    public record FeeSample(double distanceKm, BigDecimal fee) {
    }
}
