package com.openbag.enums;

/**
 * Como o pedido chega ao cliente: entrega (vai para o despacho) ou retirada na loja (sem entregador)
 */
public enum FulfillmentType {
    DELIVERY("Entrega"),
    PICKUP("Retirada");

    private final String displayName;

    FulfillmentType(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
