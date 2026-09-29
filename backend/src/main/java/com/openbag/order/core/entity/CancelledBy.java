package com.openbag.order.core.entity;

/**
 * Quem cancelou o pedido
 */
public enum CancelledBy {
    CUSTOMER("Cliente"),
    RESTAURANT("Restaurante"),
    /** Cancelamento automático (ex: restaurante não respondeu no prazo) */
    SYSTEM("Sistema");

    private final String displayName;

    CancelledBy(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
