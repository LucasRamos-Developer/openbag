package com.openbag.modules.delivery.dto;

import com.openbag.enums.CourierWorkStatus;
import com.openbag.enums.ShiftMode;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Tela "Trabalhar" do entregador: situação, turno, oferta pendente e entrega em andamento
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CourierWorkStateDTO {

    private Long deliveryPersonId;
    private CourierWorkStatus workStatus;
    private Shift shift;
    private CourierOfferDTO pendingOffer;
    private CourierOrderDTO activeOrder;
    // Todas as entregas em andamento (rota), na ordem de entrega; activeOrder é a primeira
    private List<CourierOrderDTO> activeOrders;
    private BigDecimal earnedToday;
    private int deliveriesToday;
    // Motivos que impedem ficar online (sem associação ativa, sem tabela, sem veículo)
    private List<String> blockers;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Shift {
        private Long id;
        private ShiftMode mode;
        private CourierLinkDTO.RestaurantInfo restaurant;
        private VehicleDTO vehicle;
        private LocalDateTime startedAt;
        private int deliveriesCount;
    }
}
