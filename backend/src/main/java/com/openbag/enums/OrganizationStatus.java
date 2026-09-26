package com.openbag.enums;

public enum OrganizationStatus {
    PENDING_APPROVAL("Aguardando aprovação"),
    ACTIVE("Ativa"),
    REJECTED("Recusada"),
    SUSPENDED("Suspensa");

    private final String displayName;

    OrganizationStatus(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
