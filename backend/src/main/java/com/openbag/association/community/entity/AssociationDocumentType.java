package com.openbag.association.community.entity;

/**
 * Tipo de documento da associação
 */
public enum AssociationDocumentType {
    MINUTES("Ata de reunião"),
    BYLAWS("Estatuto"),
    FINANCIAL_REPORT("Prestação de contas"),
    OTHER("Outro");

    private final String displayName;

    AssociationDocumentType(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
