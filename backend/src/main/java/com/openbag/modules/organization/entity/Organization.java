package com.openbag.modules.organization.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.openbag.enums.OrganizationStatus;
import com.openbag.enums.OrganizationType;
import com.openbag.modules.user.entity.User;
import com.openbag.modules.user.entity.Address;
import com.openbag.restaurant.store.entity.Restaurant;
import com.openbag.modules.delivery.entity.DeliveryPerson;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Associação ou cooperativa de entregadores.
 * Nasce PENDING_APPROVAL no auto-cadastro e só opera (aceita associados) depois de aprovada por um ADMIN.
 */
@Entity
@Table(name = "organizations")
@Getter
@Setter
@NoArgsConstructor
public class Organization {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(length = 20)
    private OrganizationType type = OrganizationType.ASSOCIATION;

    @Enumerated(EnumType.STRING)
    @Column(length = 20)
    private OrganizationStatus status = OrganizationStatus.PENDING_APPROVAL;

    @NotBlank
    @Size(max = 100)
    @Column(name = "company_name")
    private String companyName;

    @NotBlank
    @Size(max = 100)
    @Column(name = "trading_name")
    private String tradingName;

    @NotBlank
    @Size(max = 18)
    @Column(unique = true)
    private String cnpj;

    @Size(max = 500)
    private String description;

    @Size(max = 15)
    @Column(name = "phone_number")
    private String phoneNumber;

    @Size(max = 100)
    @Column(name = "contact_email")
    private String contactEmail;

    @Column(name = "logo_url")
    private String logoUrl;

    @Column(name = "is_active")
    private boolean isActive = true;

    @Size(max = 500)
    @Column(name = "rejection_reason")
    private String rejectionReason;

    @Column(name = "approved_at")
    private LocalDateTime approvedAt;

    // ADMIN que aprovou a organização
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "approved_by_id")
    @JsonIgnore
    private User approvedBy;

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // Relacionamento com o usuário administrador (gestor) da organização
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "admin_user_id")
    @JsonIgnore
    private User adminUser;

    // Endereço da organização
    @OneToOne(cascade = CascadeType.ALL)
    @JoinColumn(name = "address_id")
    private Address address;

    // Restaurantes associados à organização (sem cascade: não são "donos" da organização)
    @OneToMany(mappedBy = "organization", fetch = FetchType.LAZY)
    @JsonIgnore
    private List<Restaurant> restaurants = new ArrayList<>();

    // Entregadores cuja associação ativa atual é esta (cache mantido pelo MembershipService)
    @OneToMany(mappedBy = "organization", fetch = FetchType.LAZY)
    @JsonIgnore
    private List<DeliveryPerson> deliveryPersons = new ArrayList<>();

    // Tabela de valores de entrega; o Hibernate deixa null enquanto nenhuma coluna foi preenchida
    @Embedded
    private DeliveryRate deliveryRate;

    public boolean isDeliveryRateConfigured() {
        return deliveryRate != null && deliveryRate.isConfigured();
    }

    /** Cobrança da mensalidade dos cooperados (fixa ou percentual com teto) */
    @Embedded
    private MembershipFeePolicy feePolicy;

    public boolean isFeePolicyConfigured() {
        return feePolicy != null && feePolicy.isConfigured();
    }

    public boolean isOperational() {
        return status == OrganizationStatus.ACTIVE;
    }
}
