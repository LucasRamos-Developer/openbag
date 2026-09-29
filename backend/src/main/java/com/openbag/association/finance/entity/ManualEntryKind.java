package com.openbag.association.finance.entity;

/**
 * Lançamento que o gestor registra à mão no livro-caixa (as mensalidades entram sozinhas, na baixa da fatura)
 */
public enum ManualEntryKind {
    EXPENSE("Despesa", LedgerAccount.GENERAL, LedgerDirection.OUT, LedgerCategory.EXPENSE),
    INCOME("Outra entrada", LedgerAccount.GENERAL, LedgerDirection.IN, LedgerCategory.OTHER),
    CONTRIBUTION("Contribuição para a caixinha", LedgerAccount.SOLIDARITY_FUND, LedgerDirection.IN, LedgerCategory.CONTRIBUTION),
    AID("Auxílio da caixinha", LedgerAccount.SOLIDARITY_FUND, LedgerDirection.OUT, LedgerCategory.AID);

    private final String displayName;
    private final LedgerAccount account;
    private final LedgerDirection direction;
    private final LedgerCategory category;

    ManualEntryKind(String displayName, LedgerAccount account, LedgerDirection direction, LedgerCategory category) {
        this.displayName = displayName;
        this.account = account;
        this.direction = direction;
        this.category = category;
    }

    public String getDisplayName() {
        return displayName;
    }

    public LedgerAccount getAccount() {
        return account;
    }

    public LedgerDirection getDirection() {
        return direction;
    }

    public LedgerCategory getCategory() {
        return category;
    }
}
