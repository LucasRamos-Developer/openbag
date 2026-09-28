package com.openbag.modules.cooperative.entity;

import com.openbag.enums.AddonPricing;
import com.openbag.modules.organization.entity.Organization;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;

/**
 * Adicional que a associação oferece aos cooperados e cobra junto com a mensalidade (ex: seguro de vida,
 * +10% na mensalidade). A associação propõe e cada cooperado aceita ou recusa ({@link MemberAddon}).
 */
@Entity
@Table(name = "association_addon_plans",
        indexes = @Index(name = "idx_addon_plans_organization", columnList = "organization_id"))
@Getter
@Setter
@NoArgsConstructor
public class AddonPlan {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "organization_id", nullable = false)
    private Organization organization;

    @Column(nullable = false, length = 80)
    private String name;

    @Column(length = 500)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private AddonPricing pricing;

    /** Percentual da mensalidade (10 = 10%) ou valor fixo por mês, conforme {@link #pricing} */
    @Column(name = "amount", nullable = false, precision = 10, scale = 2)
    private BigDecimal value;

    @Column(nullable = false)
    private boolean active = true;

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    /** Quanto o adicional custa no mês, dada a mensalidade do cooperado */
    public BigDecimal chargeFor(BigDecimal membershipFee) {
        BigDecimal charge = pricing == AddonPricing.PERCENT_OF_FEE
                ? membershipFee.multiply(value).divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP)
                : value;
        return charge.setScale(2, RoundingMode.HALF_UP);
    }
}
