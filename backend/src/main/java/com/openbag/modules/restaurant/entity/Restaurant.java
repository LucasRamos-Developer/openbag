package com.openbag.modules.restaurant.entity;

import com.openbag.modules.user.entity.User;
import com.openbag.modules.user.entity.Address;
import com.openbag.modules.organization.entity.Organization;
import com.openbag.modules.product.entity.Product;
import com.openbag.modules.product.entity.Category;
import com.openbag.modules.order.entity.Order;
import com.openbag.enums.AcceptanceMode;
import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import com.openbag.enums.CourierPolicy;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "restaurants")
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Restaurant {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank
    @Size(max = 100)
    private String name;

    @NotBlank
    @Size(max = 100)
    @Column(unique = true)
    private String slug;

    @Size(max = 500)
    private String description;

    @NotBlank
    @Size(max = 15)
    @Column(name = "phone_number")
    private String phoneNumber;

    @NotBlank
    @Size(max = 18)
    @Column(unique = true)
    private String cnpj;

    @Column(name = "logo_url")
    private String logoUrl;

    @Column(name = "banner_url")
    private String bannerUrl;

    @NotNull
    @Column(name = "delivery_fee", precision = 10, scale = 2)
    private BigDecimal deliveryFee;

    @NotNull
    @Column(name = "minimum_order", precision = 10, scale = 2)
    private BigDecimal minimumOrder;

    @NotNull
    @Column(name = "delivery_time_min")
    private Integer deliveryTimeMin;

    @NotNull
    @Column(name = "delivery_time_max")
    private Integer deliveryTimeMax;

    @Column(precision = 10, scale = 7)
    private BigDecimal latitude;

    @Column(precision = 10, scale = 7)
    private BigDecimal longitude;

    @Column(name = "is_open")
    private boolean isOpen = true;

    @Column(name = "is_active")
    private boolean isActive = true;

    @Column(precision = 3, scale = 2)
    private BigDecimal rating = BigDecimal.ZERO;

    @Column(name = "total_reviews")
    private Integer totalReviews = 0;

    // ============= Operação =============

    @Enumerated(EnumType.STRING)
    @Column(name = "acceptance_mode", length = 10)
    private AcceptanceMode acceptanceMode = AcceptanceMode.MANUAL;

    // Prazo para aceitar um pedido no modo MANUAL; depois disso ele é cancelado automaticamente
    @Column(name = "acceptance_timeout_minutes")
    private Integer acceptanceTimeoutMinutes = 8;

    @Column(name = "default_preparation_minutes")
    private Integer defaultPreparationMinutes = 20;

    // Pausa temporária (ex: cozinha sobrecarregada); null = sem pausa
    @Column(name = "paused_until")
    private LocalDateTime pausedUntil;

    // Faixa de preço no formato schema.org ($ a $$$$)
    @Size(max = 4)
    @Column(name = "price_range", length = 4)
    private String priceRange;

    @Column(name = "auto_print_ticket")
    private Boolean autoPrintTicket = false;

    // ============= Entregadores =============

    @Enumerated(EnumType.STRING)
    @Column(name = "courier_policy", length = 20)
    private CourierPolicy courierPolicy;

    // Com FIXED_ONLY: se nenhum fixo estiver disponível, o pedido é oferecido no modo livre
    @Column(name = "fallback_to_open")
    private Boolean fallbackToOpen;

    // O restaurante assume a diferença quando o valor da tabela da associação passa da taxa cobrada do cliente
    @Column(name = "covers_delivery_difference")
    private Boolean coversDeliveryDifference;

    @Column(name = "covers_delivery_difference_at")
    private LocalDateTime coversDeliveryDifferenceAcceptedAt;

    // Entregador livre que não aparece na loja: depois destes minutos a loja pode trocá-lo
    @Column(name = "courier_no_show_minutes")
    private Integer courierNoShowMinutes;

    // ============= Rotas =============

    // Junta entregas do mesmo bairro/direção e chama o entregador perto de ficarem prontas
    @Column(name = "route_batching_enabled")
    private Boolean routeBatchingEnabled;

    @Column(name = "route_max_orders")
    private Integer routeMaxOrders;

    // Quanto um pedido pronto pode esperar outro da mesma rota
    @Column(name = "route_max_hold_minutes")
    private Integer routeMaxHoldMinutes;

    // Quantos minutos antes de o pedido ficar pronto o entregador é chamado
    @Column(name = "route_dispatch_lead_minutes")
    private Integer routeDispatchLeadMinutes;

    public boolean isRouteBatchingEnabled() {
        return routeBatchingEnabled == null || routeBatchingEnabled;
    }

    public int getRouteMaxOrders() {
        return routeMaxOrders != null ? routeMaxOrders : 3;
    }

    public int getRouteMaxHoldMinutes() {
        return routeMaxHoldMinutes != null ? routeMaxHoldMinutes : 8;
    }

    public int getRouteDispatchLeadMinutes() {
        return routeDispatchLeadMinutes != null ? routeDispatchLeadMinutes : 10;
    }

    public int getCourierNoShowMinutes() {
        return courierNoShowMinutes != null ? courierNoShowMinutes : 10;
    }

    public CourierPolicy getCourierPolicy() {
        return courierPolicy != null ? courierPolicy : CourierPolicy.OPEN;
    }

    public boolean isFallbackToOpen() {
        return Boolean.TRUE.equals(fallbackToOpen);
    }

    public boolean isCoversDeliveryDifference() {
        return Boolean.TRUE.equals(coversDeliveryDifference);
    }

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "owner_id")
    private User owner;

    // Organização à qual o restaurante pode pertencer (opcional)
    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "organization_id")
    private Organization organization;

    @OneToOne(cascade = CascadeType.ALL)
    @JoinColumn(name = "address_id")
    private Address address;

    @JsonIgnore
    @OneToMany(mappedBy = "restaurant", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Product> products = new ArrayList<>();

    @JsonIgnore
    @OneToMany(mappedBy = "restaurant", fetch = FetchType.LAZY)
    private List<Order> orders = new ArrayList<>();

    @ManyToMany
    @JoinTable(
        name = "restaurant_categories",
        joinColumns = @JoinColumn(name = "restaurant_id"),
        inverseJoinColumns = @JoinColumn(name = "category_id")
    )
    private List<Category> categories = new ArrayList<>();

    @OneToOne(mappedBy = "restaurant", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private LayoutConfig layoutConfig;

    @OneToMany(mappedBy = "restaurant", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<OpeningHour> openingHours = new ArrayList<>();

    // ============= Padrões para linhas criadas antes destas colunas existirem (valores NULL no banco) =============

    public AcceptanceMode getAcceptanceMode() {
        return acceptanceMode != null ? acceptanceMode : AcceptanceMode.MANUAL;
    }

    public Integer getAcceptanceTimeoutMinutes() {
        return acceptanceTimeoutMinutes != null ? acceptanceTimeoutMinutes : 8;
    }

    public Integer getDefaultPreparationMinutes() {
        return defaultPreparationMinutes != null ? defaultPreparationMinutes : 20;
    }

    public boolean isAutoPrintTicket() {
        return Boolean.TRUE.equals(autoPrintTicket);
    }

    // ============= Helpers =============

    public boolean isPaused(LocalDateTime now) {
        return pausedUntil != null && pausedUntil.isAfter(now);
    }

    /**
     * Se o restaurante está recebendo pedidos agora: ativo, não fechado manualmente,
     * sem pausa e dentro de algum horário de funcionamento (sem horários cadastrados, vale só o flag manual)
     */
    public boolean isOpenNow(LocalDateTime now) {
        if (!isActive || !isOpen || isPaused(now)) {
            return false;
        }
        if (openingHours == null || openingHours.isEmpty()) {
            return true;
        }
        return openingHours.stream().anyMatch(hour -> hour.covers(now));
    }
}
