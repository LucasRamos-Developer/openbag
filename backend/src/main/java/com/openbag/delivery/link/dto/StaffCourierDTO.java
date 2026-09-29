package com.openbag.delivery.link.dto;

import com.openbag.delivery.link.entity.StaffCourier;

import java.math.BigDecimal;

/**
 * Entregador da equipe própria da loja
 */
public record StaffCourierDTO(Long id, String name, String phone, BigDecimal feePerDelivery) {

    public static StaffCourierDTO from(StaffCourier staff) {
        return new StaffCourierDTO(staff.getId(), staff.getName(), staff.getPhone(), staff.getFeePerDelivery());
    }
}
