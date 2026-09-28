package com.openbag.enums;

/**
 * Item da fatura
 */
public enum InvoiceLineType {
    FEE("Mensalidade"),
    ADDON("Adicional"),
    SOLIDARITY("Caixinha solidária");

    private final String displayName;

    InvoiceLineType(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
