package com.openbag.association.finance.entity;

/**
 * Natureza do lançamento
 */
public enum LedgerCategory {
    MEMBERSHIP_FEE("Mensalidade"),
    ADDON("Adicional"),
    CONTRIBUTION("Contribuição"),
    AID("Auxílio a cooperado"),
    EXPENSE("Despesa"),
    OTHER("Outro");

    private final String displayName;

    LedgerCategory(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
