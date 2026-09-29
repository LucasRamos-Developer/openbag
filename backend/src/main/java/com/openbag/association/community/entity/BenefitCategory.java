package com.openbag.association.community.entity;

/**
 * Tipo de convênio que a associação oferece aos cooperados
 */
public enum BenefitCategory {
    WORKSHOP("Oficina"),
    LANGUAGES("Idiomas"),
    EDUCATION("Cursos"),
    HEALTH("Saúde"),
    FUEL("Combustível"),
    PARTS("Peças e acessórios"),
    FOOD("Alimentação"),
    OTHER("Outros");

    private final String displayName;

    BenefitCategory(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
