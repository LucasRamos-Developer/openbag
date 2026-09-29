package com.openbag.association.finance.entity;

import com.openbag.enums.LedgerAccount;
import com.openbag.enums.LedgerCategory;
import com.openbag.enums.LedgerDirection;
import com.openbag.association.core.entity.AssociationMembership;
import com.openbag.association.core.entity.Organization;
import com.openbag.modules.user.entity.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Lançamento do livro-caixa da associação: entradas (mensalidades, adicionais, contribuições) e saídas
 * (despesas, auxílios da caixinha). Duas contas: o caixa geral e a caixinha solidária.
 * Os lançamentos das faturas são criados na baixa e removidos se a baixa for desfeita.
 */
@Entity
@Table(name = "ledger_entries",
        indexes = @Index(name = "idx_ledger_organization_date", columnList = "organization_id,entry_date"))
@Getter
@Setter
@NoArgsConstructor
public class LedgerEntry {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "organization_id", nullable = false)
    private Organization organization;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private LedgerAccount account;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 5)
    private LedgerDirection direction;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private LedgerCategory category;

    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal amount;

    @Column(name = "entry_date", nullable = false)
    private LocalDate date;

    @Column(nullable = false, length = 200)
    private String description;

    /** Cooperado ligado ao lançamento (quem pagou ou quem recebeu o auxílio) */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "membership_id")
    private AssociationMembership membership;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "invoice_id")
    private MemberInvoice invoice;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by_id")
    private User createdBy;

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    /** Valor com sinal: entrada positiva, saída negativa */
    public BigDecimal signedAmount() {
        return direction == LedgerDirection.IN ? amount : amount.negate();
    }
}
