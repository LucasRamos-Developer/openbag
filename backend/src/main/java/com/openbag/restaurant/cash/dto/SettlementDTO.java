package com.openbag.restaurant.cash.dto;

import com.openbag.delivery.dispatch.service.ReassignPolicy.CourierKind;
import com.openbag.restaurant.cash.entity.CourierSettlement;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Acerto feito entre a loja e um entregador; saldo positivo = o entregador devolveu à loja
 */
public record SettlementDTO(Long id, CourierKind kind, String name, int ordersCount, BigDecimal cashCollected,
                            BigDecimal courierEarnings, BigDecimal balance, LocalDateTime settledAt, String settledBy) {

    public static SettlementDTO from(CourierSettlement s) {
        boolean staff = s.getStaffCourier() != null;
        return new SettlementDTO(s.getId(), staff ? CourierKind.STAFF : CourierKind.FREE,
                staff ? s.getStaffCourier().getName() : s.getDeliveryPerson().getUser().getFullName(),
                s.getOrdersCount(), s.getCashCollected(), s.getCourierEarnings(), s.getBalance(), s.getSettledAt(),
                s.getSettledBy() != null ? s.getSettledBy().getFullName() : null);
    }
}
