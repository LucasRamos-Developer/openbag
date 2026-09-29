package com.openbag.association.core.entity;

/**
 * Como a associação cobra a mensalidade do cooperado
 */
public enum MembershipFeeMode {
    FIXED("Valor fixo"),
    PERCENTAGE("Percentual dos ganhos");

    private final String displayName;

    MembershipFeeMode(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
