package com.openbag.modules.organization.entity;

import com.openbag.enums.MembershipOrigin;
import com.openbag.enums.MembershipStatus;
import com.openbag.delivery.courier.entity.DeliveryPerson;
import com.openbag.modules.user.entity.User;
import jakarta.persistence.*;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Vínculo de um entregador com uma associação/cooperativa.
 * Guarda o histórico: cada entrada/saída gera um registro novo, e o entregador
 * só pode ter um vínculo em {@link MembershipStatus#OPEN} por vez.
 */
@Entity
@Table(
    name = "association_memberships",
    indexes = {
        @Index(name = "idx_membership_org_status", columnList = "organization_id, status"),
        @Index(name = "idx_membership_delivery_person", columnList = "delivery_person_id")
    },
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_membership_org_member_number", columnNames = {"organization_id", "member_number"})
    }
)
@Getter
@Setter
@NoArgsConstructor
public class AssociationMembership {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "organization_id", nullable = false)
    private Organization organization;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "delivery_person_id", nullable = false)
    private DeliveryPerson deliveryPerson;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private MembershipStatus status;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private MembershipOrigin origin;

    // Número de matrícula na associação, atribuído na primeira ativação
    @Column(name = "member_number")
    private Integer memberNumber;

    // Convite usado para entrar (quando origin = INVITE)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "invite_id")
    private AssociationInvite invite;

    @Column(name = "requested_at", nullable = false)
    private LocalDateTime requestedAt;

    // Última decisão do gestor (aprovação, recusa, suspensão, reativação, desligamento)
    @Column(name = "decided_at")
    private LocalDateTime decidedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "decided_by_id")
    private User decidedBy;

    @Column(name = "ended_at")
    private LocalDateTime endedAt;

    // Motivo da última recusa/suspensão/desligamento
    @Size(max = 500)
    @Column(length = 500)
    private String reason;

    // Quanto o cooperado quer dar por mês à caixinha solidária (entra na fatura; nulo ou zero = nada)
    @Column(name = "solidarity_contribution", precision = 10, scale = 2)
    private BigDecimal solidarityContribution;

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
