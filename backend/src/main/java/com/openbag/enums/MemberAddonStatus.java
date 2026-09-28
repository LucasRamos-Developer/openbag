package com.openbag.enums;

/**
 * Situação do adicional para o cooperado: a associação propõe e ele aceita ou recusa
 */
public enum MemberAddonStatus {
    PROPOSED("Proposto"),
    ACTIVE("Ativo"),
    DECLINED("Recusado"),
    CANCELLED("Cancelado");

    private final String displayName;

    MemberAddonStatus(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
