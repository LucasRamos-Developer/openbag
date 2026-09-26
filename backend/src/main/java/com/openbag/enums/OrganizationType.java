package com.openbag.enums;

public enum OrganizationType {
    ASSOCIATION("Associação"),
    COOPERATIVE("Cooperativa");

    private final String displayName;

    OrganizationType(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
