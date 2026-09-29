package com.openbag.association.partnership.entity;

import com.openbag.enums.PartnershipSide;
import com.openbag.enums.PartnershipStatus;
import com.openbag.association.core.entity.DeliveryRate;
import com.openbag.association.core.entity.Organization;
import com.openbag.restaurant.store.entity.Restaurant;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

/**
 * Parceria entre restaurante e associação. Um lado pede, o outro aceita ou recusa, e qualquer lado encerra.
 * Só a parceria ACTIVE vale para a política PARTNERS_ONLY. O histórico fica.
 *
 * Acordo: a parceria pode ter uma tabela especial ({@code agreedRate}) que substitui a tabela da associação
 * nesta loja. Ela só muda com o aceite dos dois lados: um propõe ({@code proposedRate}) e o outro aceita.
 */
@Entity
@Table(name = "restaurant_partnerships",
        indexes = {
                @Index(name = "idx_partnership_restaurant", columnList = "restaurant_id"),
                @Index(name = "idx_partnership_organization", columnList = "organization_id")
        })
@Getter
@Setter
@NoArgsConstructor
public class RestaurantPartnership {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "restaurant_id", nullable = false)
    private Restaurant restaurant;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "organization_id", nullable = false)
    private Organization organization;

    // Nulo nas parcerias criadas antes do aceite (valiam direto): ver getStatus()
    @Enumerated(EnumType.STRING)
    @Column(name = "status", length = 20)
    private PartnershipStatus status;

    @Enumerated(EnumType.STRING)
    @Column(name = "requested_by", length = 20)
    private PartnershipSide requestedBy;

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "decided_at")
    private LocalDateTime decidedAt;

    @Column(name = "ended_at")
    private LocalDateTime endedAt;

    @Enumerated(EnumType.STRING)
    @Column(name = "ended_by", length = 20)
    private PartnershipSide endedBy;

    // ============= Acordo (tabela especial) =============

    @Embedded
    @AttributeOverrides({
            @AttributeOverride(name = "baseFee", column = @Column(name = "agreed_base_fee", precision = 10, scale = 2)),
            @AttributeOverride(name = "baseDistanceKm",
                    column = @Column(name = "agreed_base_distance_km", precision = 5, scale = 2)),
            @AttributeOverride(name = "extraPerKm",
                    column = @Column(name = "agreed_extra_per_km", precision = 10, scale = 2))
    })
    private DeliveryRate agreedRate;

    @Column(name = "agreed_at")
    private LocalDateTime agreedAt;

    @Embedded
    @AttributeOverrides({
            @AttributeOverride(name = "baseFee", column = @Column(name = "proposed_base_fee", precision = 10, scale = 2)),
            @AttributeOverride(name = "baseDistanceKm",
                    column = @Column(name = "proposed_base_distance_km", precision = 5, scale = 2)),
            @AttributeOverride(name = "extraPerKm",
                    column = @Column(name = "proposed_extra_per_km", precision = 10, scale = 2))
    })
    private DeliveryRate proposedRate;

    // Proposta de voltar à tabela padrão da associação (sem proposedRate)
    @Column(name = "rate_proposal_to_default")
    private Boolean rateProposalToDefault;

    @Enumerated(EnumType.STRING)
    @Column(name = "rate_proposed_by", length = 20)
    private PartnershipSide rateProposedBy;

    @Column(name = "rate_proposed_at")
    private LocalDateTime rateProposedAt;

    public PartnershipStatus getStatus() {
        if (status != null) {
            return status;
        }
        return endedAt == null ? PartnershipStatus.ACTIVE : PartnershipStatus.ENDED;
    }

    public boolean isActive() {
        return getStatus() == PartnershipStatus.ACTIVE;
    }

    public boolean hasAgreedRate() {
        return agreedRate != null && agreedRate.isConfigured();
    }

    public boolean hasRateProposal() {
        return rateProposedBy != null;
    }

    public boolean isRateProposalToDefault() {
        return Boolean.TRUE.equals(rateProposalToDefault);
    }

    /**
     * Quem precisa responder agora (null = ninguém).
     * Num pedido pendente é o outro lado de quem fez a última jogada (o pedido ou uma contraproposta de tabela);
     * numa parceria ativa, o outro lado da proposta de tabela que está aberta.
     */
    public PartnershipSide getAwaitingSide() {
        PartnershipStatus current = getStatus();
        if (current == PartnershipStatus.PENDING) {
            return hasRateProposal() ? rateProposedBy.other() : requestedBy.other();
        }
        if (current == PartnershipStatus.ACTIVE && hasRateProposal()) {
            return rateProposedBy.other();
        }
        return null;
    }

    /** Tabela que vale nesta loja: a especial, se houver, ou a da associação */
    public DeliveryRate getEffectiveRate() {
        return hasAgreedRate() ? agreedRate : organization.getDeliveryRate();
    }

    public void clearRateProposal() {
        proposedRate = null;
        rateProposalToDefault = null;
        rateProposedBy = null;
        rateProposedAt = null;
    }
}
