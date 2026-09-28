package com.openbag.modules.cooperative.entity;

import com.openbag.enums.BenefitCategory;
import com.openbag.modules.organization.entity.Organization;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Convênio da associação com um parceiro (oficina, escola de idiomas, desconto em peças...), disponível aos
 * cooperados. Some da lista deles quando é desativado ou passa da validade.
 */
@Entity
@Table(name = "association_benefits",
        indexes = @Index(name = "idx_benefits_organization", columnList = "organization_id"))
@Getter
@Setter
@NoArgsConstructor
public class Benefit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "organization_id", nullable = false)
    private Organization organization;

    @Column(name = "partner_name", nullable = false, length = 120)
    private String partnerName;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private BenefitCategory category;

    /** O benefício em poucas palavras: "15% em peças", "Matrícula grátis" */
    @Column(nullable = false, length = 120)
    private String headline;

    @Column(length = 1000)
    private String description;

    @Column(length = 250)
    private String address;

    @Column(length = 20)
    private String phone;

    @Column(length = 300)
    private String link;

    @Column(name = "logo_url")
    private String logoUrl;

    @Column(name = "valid_until")
    private LocalDate validUntil;

    @Column(nullable = false)
    private boolean active = true;

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    public boolean isAvailable(LocalDate today) {
        return active && (validUntil == null || !validUntil.isBefore(today));
    }
}
