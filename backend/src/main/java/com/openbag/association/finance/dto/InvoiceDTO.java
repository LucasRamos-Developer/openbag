package com.openbag.association.finance.dto;

import com.openbag.association.finance.entity.InvoiceLineType;
import com.openbag.association.finance.entity.InvoiceStatus;
import com.openbag.association.finance.entity.MemberPaymentMethod;
import com.openbag.association.finance.entity.MemberInvoice;
import com.openbag.association.finance.entity.MemberInvoiceLine;
import com.openbag.association.core.entity.AssociationMembership;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Fatura do cooperado. {@code preview} = mês ainda em andamento, calculada na hora e sem id (vira fatura
 * quando o mês fecha).
 */
public record InvoiceDTO(Long id, boolean preview, Long membershipId, Integer memberNumber, String memberName,
                         LocalDate month, BigDecimal earnings, int deliveries, List<Line> lines, BigDecimal total,
                         InvoiceStatus status, LocalDate dueDate, boolean overdue, LocalDate paidOn,
                         MemberPaymentMethod paymentMethod, String notes) {

    public record Line(InvoiceLineType type, String description, BigDecimal amount) {
        static Line from(MemberInvoiceLine line) {
            return new Line(line.getType(), line.getDescription(), line.getAmount());
        }
    }

    public static InvoiceDTO from(MemberInvoice invoice, LocalDate today) {
        AssociationMembership membership = invoice.getMembership();
        return new InvoiceDTO(invoice.getId(), false, membership.getId(), membership.getMemberNumber(),
                membership.getDeliveryPerson().getUser().getFullName(), invoice.getMonth(), invoice.getEarnings(),
                invoice.getDeliveries(), invoice.getLines().stream().map(Line::from).toList(), invoice.getTotal(),
                invoice.getStatus(), invoice.getDueDate(),
                invoice.getStatus() == InvoiceStatus.OPEN && invoice.getDueDate().isBefore(today),
                invoice.getPaidOn(), invoice.getPaymentMethod(), invoice.getNotes());
    }

    /** Prévia do mês em andamento (mesma conta, sem gravar) */
    public static InvoiceDTO preview(MemberInvoice draft) {
        AssociationMembership membership = draft.getMembership();
        return new InvoiceDTO(null, true, membership.getId(), membership.getMemberNumber(),
                membership.getDeliveryPerson().getUser().getFullName(), draft.getMonth(), draft.getEarnings(),
                draft.getDeliveries(), draft.getLines().stream().map(Line::from).toList(), draft.getTotal(),
                InvoiceStatus.OPEN, draft.getDueDate(), false, null, null, null);
    }
}
