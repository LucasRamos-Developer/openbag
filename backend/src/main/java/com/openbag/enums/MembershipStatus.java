package com.openbag.enums;

import java.util.EnumSet;
import java.util.Set;

public enum MembershipStatus {
    PENDING("Aguardando aprovação"),
    ACTIVE("Ativo"),
    SUSPENDED("Suspenso"),
    REJECTED("Recusado"),
    LEFT("Desligou-se"),
    REMOVED("Desligado pela associação");

    /**
     * Status que ocupam o vínculo do entregador: ele só pode ter um vínculo nesses status por vez
     */
    public static final Set<MembershipStatus> OPEN = EnumSet.of(PENDING, ACTIVE, SUSPENDED);

    private final String displayName;

    MembershipStatus(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
