package com.openbag.modules.cooperative.entity;

import com.openbag.enums.MemberAddonStatus;
import com.openbag.modules.organization.entity.AssociationMembership;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

/**
 * Adicional de um cooperado: proposto pela associação, aceito ou recusado por ele. Só o ativo entra na fatura.
 */
@Entity
@Table(name = "member_addons",
        indexes = @Index(name = "idx_member_addons_membership", columnList = "membership_id"))
@Getter
@Setter
@NoArgsConstructor
public class MemberAddon {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "membership_id", nullable = false)
    private AssociationMembership membership;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "plan_id", nullable = false)
    private AddonPlan plan;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private MemberAddonStatus status;

    @CreationTimestamp
    @Column(name = "proposed_at")
    private LocalDateTime proposedAt;

    @Column(name = "decided_at")
    private LocalDateTime decidedAt;

    @Column(name = "cancelled_at")
    private LocalDateTime cancelledAt;

    public boolean isOpen() {
        return status == MemberAddonStatus.PROPOSED || status == MemberAddonStatus.ACTIVE;
    }
}
