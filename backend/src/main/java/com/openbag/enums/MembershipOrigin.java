package com.openbag.enums;

public enum MembershipOrigin {
    SELF_REQUEST("Solicitação do entregador"),
    MANAGER_CREATED("Cadastrado pelo gestor"),
    INVITE("Código de convite");

    private final String displayName;

    MembershipOrigin(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
