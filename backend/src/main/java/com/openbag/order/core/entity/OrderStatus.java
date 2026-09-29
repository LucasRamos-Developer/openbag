package com.openbag.order.core.entity;

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

    /**
     * Mudanças de status possíveis. Toda mudança passa por aqui (restaurante, entregador, cliente e jobs), então
     * duas ações que disputam o mesmo pedido nunca levam a um caminho que não existe (ex.: entregue depois de
     * cancelado). Cada ação ainda restringe a origem, como "o cliente só cancela antes do aceite".
     */
    public boolean canTransitionTo(OrderStatus target) {
        return switch (this) {
            case PENDING -> target == CONFIRMED || target == CANCELLED;
            case CONFIRMED -> target == PREPARING || target == READY_FOR_PICKUP || target == CANCELLED;
            case PREPARING -> target == READY_FOR_PICKUP || target == CANCELLED;
            // Retirada: o cliente busca o pedido pronto no balcão
            case READY_FOR_PICKUP -> target == OUT_FOR_DELIVERY || target == DELIVERED;
            case OUT_FOR_DELIVERY -> target == DELIVERED;
            case DELIVERED, CANCELLED -> false;
        };
    }

    @Override
    public String toString() {
        return displayName;
    }
}
