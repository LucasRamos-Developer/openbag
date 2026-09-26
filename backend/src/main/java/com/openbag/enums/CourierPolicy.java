package com.openbag.enums;

/**
 * Quais entregadores podem receber os pedidos do restaurante
 */
public enum CourierPolicy {
    OPEN("Qualquer entregador"),
    PARTNERS_ONLY("Só associações parceiras"),
    FIXED_ONLY("Só entregadores fixos");

    private final String displayName;

    CourierPolicy(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
