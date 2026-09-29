package com.openbag.association.finance.entity;

/**
 * Conta do livro-caixa da associação
 */
public enum LedgerAccount {
    GENERAL("Caixa da associação"),
    SOLIDARITY_FUND("Caixinha solidária");

    private final String displayName;

    LedgerAccount(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
