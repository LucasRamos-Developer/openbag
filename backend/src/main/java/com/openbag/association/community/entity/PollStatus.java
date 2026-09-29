package com.openbag.association.community.entity;

/**
 * Situação da enquete
 */
public enum PollStatus {
    DRAFT("Rascunho"),
    OPEN("Aberta"),
    CLOSED("Encerrada");

    private final String displayName;

    PollStatus(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
