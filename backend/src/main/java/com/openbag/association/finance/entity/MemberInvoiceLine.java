package com.openbag.association.finance.entity;

import com.openbag.enums.InvoiceLineType;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

/** Item da fatura: a mensalidade, cada adicional ou a contribuição para a caixinha */
@Entity
@Table(name = "member_invoice_lines")
@Getter
@Setter
@NoArgsConstructor
public class MemberInvoiceLine {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "invoice_id", nullable = false)
    private MemberInvoice invoice;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private InvoiceLineType type;

    @Column(nullable = false, length = 120)
    private String description;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal amount;

    public MemberInvoiceLine(InvoiceLineType type, String description, BigDecimal amount) {
        this.type = type;
        this.description = description;
        this.amount = amount;
    }
}
