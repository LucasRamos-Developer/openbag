package com.openbag.order.core.entity;

/**
 * Por onde o pedido chegou: pelo app (o cliente fez) ou registrado pela loja (balcão, telefone, WhatsApp)
 */
public enum OrderChannel {
    APP("App"),
    COUNTER("Balcão"),
    PHONE("Telefone"),
    WHATSAPP("WhatsApp");

    private final String displayName;

    OrderChannel(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
