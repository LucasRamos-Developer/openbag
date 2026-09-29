package com.openbag.association.finance.entity;

/**
 * Como o cooperado pagou a fatura (a baixa é manual)
 */
public enum MemberPaymentMethod {
    PIX("Pix"),
    CASH("Dinheiro"),
    TRANSFER("Transferência"),
    OTHER("Outro");

    private final String displayName;

    MemberPaymentMethod(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
