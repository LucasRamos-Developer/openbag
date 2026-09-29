package com.openbag.delivery.courier.dto;

import com.openbag.enums.ShiftMode;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Onde o entregador trabalhou: restaurantes com entregas feitas e os turnos recentes
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WorkHistoryDTO {

    private List<RestaurantEntry> restaurants;
    private List<ShiftEntry> recentShifts;

    public record RestaurantEntry(Long restaurantId, String name, String slug, String logoUrl, long deliveries,
                                  LocalDateTime firstDeliveryAt, LocalDateTime lastDeliveryAt, boolean fixed) {
    }

    public record ShiftEntry(Long id, ShiftMode mode, String restaurantName, LocalDateTime startedAt,
                             LocalDateTime endedAt, int deliveries) {
    }
}
