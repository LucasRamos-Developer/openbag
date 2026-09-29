package com.openbag.association.finance.dto;

import com.openbag.enums.LedgerAccount;
import com.openbag.enums.LedgerCategory;
import com.openbag.enums.LedgerDirection;
import com.openbag.association.finance.entity.LedgerEntry;
import com.openbag.association.core.entity.AssociationMembership;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Lançamento do livro-caixa. {@code manual} = registrado pelo gestor (pode ser apagado); os das faturas saem
 * desfazendo a baixa.
 */
public record LedgerEntryDTO(Long id, LedgerAccount account, LedgerDirection direction, LedgerCategory category,
                             BigDecimal amount, LocalDate date, String description, Long membershipId,
                             Integer memberNumber, String memberName, Long invoiceId, boolean manual) {

    public static LedgerEntryDTO from(LedgerEntry entry) {
        AssociationMembership membership = entry.getMembership();
        return new LedgerEntryDTO(entry.getId(), entry.getAccount(), entry.getDirection(), entry.getCategory(),
                entry.getAmount(), entry.getDate(), entry.getDescription(),
                membership != null ? membership.getId() : null,
                membership != null ? membership.getMemberNumber() : null,
                membership != null ? membership.getDeliveryPerson().getUser().getFullName() : null,
                entry.getInvoice() != null ? entry.getInvoice().getId() : null,
                entry.getInvoice() == null);
    }
}
