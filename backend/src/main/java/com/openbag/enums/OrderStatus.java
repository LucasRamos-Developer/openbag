package com.openbag.enums;

public enum OrderStatus {
    PENDING("Aguardando aceite"),
    CONFIRMED("Confirmado"),
    PREPARING("Em preparo"),
    READY_FOR_PICKUP("Pronto"),
    OUT_FOR_DELIVERY("Saiu para entrega"),
    DELIVERED("Entregue"),
    CANCELLED("Cancelado");

    private final String displayName;

    OrderStatus(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }

    @Override
    public String toString() {
        return displayName;
    }
}
