package com.openbag.enums;

/**
 * Como o restaurante recebe pedidos novos
 */
public enum AcceptanceMode {
    /** O pedido chega como PENDING e o restaurante aceita ou recusa dentro do prazo */
    MANUAL("Aceite manual"),
    /** O pedido entra direto como CONFIRMED */
    AUTO("Aceite automático");

    private final String displayName;

    AcceptanceMode(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
