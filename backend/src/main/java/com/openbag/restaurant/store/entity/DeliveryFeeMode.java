package com.openbag.restaurant.store.entity;

/**
 * Como a loja cobra a entrega do cliente
 */
public enum DeliveryFeeMode {
    /** Taxa fixa definida pela loja; se a tabela do entregador passar dela, a loja pode assumir a diferença */
    ASSUME("Taxa fixa da loja"),
    /** O cliente paga pela distância, pela maior tabela das associações; o entregador recebe o valor inteiro */
    PASS_THROUGH("Repassar ao cliente");

    private final String displayName;

    DeliveryFeeMode(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
