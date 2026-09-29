package com.openbag.association.finance.entity;

/**
 * Entrada ou saída de dinheiro
 */
public enum LedgerDirection {
    IN("Entrada"),
    OUT("Saída");

    private final String displayName;

    LedgerDirection(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
