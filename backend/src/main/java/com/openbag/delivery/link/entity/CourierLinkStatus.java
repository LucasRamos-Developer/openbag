package com.openbag.delivery.link.entity;

import java.util.EnumSet;
import java.util.Set;

/**
 * Vínculo de entregador fixo com um restaurante
 */
public enum CourierLinkStatus {
    PENDING("Pendente"),
    ACTIVE("Ativo"),
    REJECTED("Recusado"),
    ENDED("Encerrado");

    // Vínculos que impedem abrir outro para o mesmo par restaurante/entregador
    public static final Set<CourierLinkStatus> OPEN = EnumSet.of(PENDING, ACTIVE);

    private final String displayName;

    CourierLinkStatus(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
