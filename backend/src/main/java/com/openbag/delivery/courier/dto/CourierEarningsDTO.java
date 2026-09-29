package com.openbag.delivery.courier.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Ganhos do entregador: resumo (hoje, semana, mês), série diária e entregas do período
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CourierEarningsDTO {

    private Total today;
    private Total week;
    private Total month;

    private LocalDate from;
    private LocalDate to;
    private Total period;
    private List<Day> daily;
    private List<Delivery> deliveries;

    public record Total(BigDecimal amount, long deliveries) {
    }

    public record Day(LocalDate date, BigDecimal amount, long deliveries) {
    }

    public record Delivery(Long orderId, String displayCode, LocalDateTime deliveredAt, String restaurantName,
                           Double distanceKm, BigDecimal courierFee) {
    }
}
