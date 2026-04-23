package com.openbag.modules.organization.entity;

import com.openbag.modules.user.entity.User;
import com.openbag.modules.user.entity.Address;
import com.openbag.modules.restaurant.entity.Restaurant;
import com.openbag.modules.delivery.entity.DeliveryPerson;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "organizations")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Organization {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

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

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // Relacionamento com o usuário administrador da organização
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "admin_user_id")
    private User adminUser;

    // Endereço da organização
    @OneToOne(cascade = CascadeType.ALL)
    @JoinColumn(name = "address_id")
    private Address address;

    // Restaurantes associados à organização
    @OneToMany(mappedBy = "organization", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Restaurant> restaurants = new ArrayList<>();

    // Entregadores associados à organização
    @OneToMany(mappedBy = "organization", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<DeliveryPerson> deliveryPersons = new ArrayList<>();
}
