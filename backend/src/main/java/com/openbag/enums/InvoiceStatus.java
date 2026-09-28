package com.openbag.enums;

/**
 * Situação da fatura mensal do cooperado
 */
public enum InvoiceStatus {
    OPEN("Em aberto"),
    PAID("Paga"),
    WAIVED("Dispensada");

    private final String displayName;

    InvoiceStatus(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
