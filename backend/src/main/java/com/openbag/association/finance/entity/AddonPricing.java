package com.openbag.association.finance.entity;

/**
 * Como o adicional (ex: seguro de vida) é cobrado
 */
public enum AddonPricing {
    PERCENT_OF_FEE("Percentual da mensalidade"),
    FIXED("Valor fixo por mês");

    private final String displayName;

    AddonPricing(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
