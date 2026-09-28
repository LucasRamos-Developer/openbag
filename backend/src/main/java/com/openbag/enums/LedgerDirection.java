package com.openbag.enums;

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
