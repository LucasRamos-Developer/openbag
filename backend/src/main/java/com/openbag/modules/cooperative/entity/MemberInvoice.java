package com.openbag.modules.cooperative.entity;

import com.openbag.enums.InvoiceStatus;
import com.openbag.enums.MemberPaymentMethod;
import com.openbag.modules.organization.entity.AssociationMembership;
import com.openbag.modules.organization.entity.Organization;
import com.openbag.modules.user.entity.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Fatura mensal do cooperado: mensalidade, adicionais e contribuição para a caixinha solidária.
 * Uma por cooperado e por mês ({@code month} é o primeiro dia do mês de referência). A baixa é manual.
 */
@Entity
@Table(name = "member_invoices",
        uniqueConstraints = @UniqueConstraint(name = "uk_member_invoices_membership_month",
                columnNames = {"membership_id", "reference_month"}),
        indexes = @Index(name = "idx_member_invoices_organization_month", columnList = "organization_id,reference_month"))
@Getter
@Setter
@NoArgsConstructor
public class MemberInvoice {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "organization_id", nullable = false)
    private Organization organization;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "membership_id", nullable = false)
    private AssociationMembership membership;

    @Column(name = "reference_month", nullable = false)
    private LocalDate month;

    /** Ganhos do cooperado no mês (base da mensalidade percentual) */
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal earnings;

    @Column(name = "deliveries", nullable = false)
    private int deliveries;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal total;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private InvoiceStatus status;

    @Column(name = "due_date", nullable = false)
    private LocalDate dueDate;

    @Column(name = "paid_on")
    private LocalDate paidOn;

    @Enumerated(EnumType.STRING)
    @Column(name = "payment_method", length = 20)
    private MemberPaymentMethod paymentMethod;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "registered_by_id")
    private User registeredBy;

    @Column(length = 500)
    private String notes;

    @OneToMany(mappedBy = "invoice", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("id")
    private List<MemberInvoiceLine> lines = new ArrayList<>();

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    public void addLine(MemberInvoiceLine line) {
        line.setInvoice(this);
        lines.add(line);
    }
}
