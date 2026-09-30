package com.openbag.order.core.entity;

import com.openbag.account.entity.User;
import com.openbag.restaurant.store.entity.Restaurant;
import com.openbag.delivery.courier.entity.DeliveryPerson;
import com.openbag.restaurant.cash.entity.CourierSettlement;
import com.openbag.delivery.route.entity.DeliveryRoute;
import com.openbag.delivery.link.entity.StaffCourier;
import com.openbag.association.core.entity.Organization;
import com.openbag.order.incident.entity.OrderIncident;
import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
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
@Table(name = "orders")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Trava otimista: duas gravações feitas a partir da mesma leitura não se sobrescrevem (a segunda falha com 409) */
    @Version
    @lombok.EqualsAndHashCode.Exclude
    private Long version;

    @Column(name = "order_number", unique = true)
    private String orderNumber;

    @NotNull
    @Column(name = "subtotal", precision = 10, scale = 2)
    private BigDecimal subtotal;

    @NotNull
    @Column(name = "delivery_fee", precision = 10, scale = 2)
    private BigDecimal deliveryFee;

    @NotNull
    @Column(name = "total_amount", precision = 10, scale = 2)
    private BigDecimal totalAmount;

    @NotNull
    @Column(name = "order_date")
    private LocalDateTime orderDate;

    @Enumerated(EnumType.STRING)
    private OrderStatus status = OrderStatus.PENDING;

    @Enumerated(EnumType.STRING)
    @Column(name = "payment_method")
    private PaymentMethod paymentMethod;

    @Enumerated(EnumType.STRING)
    @Column(name = "payment_status")
    private PaymentStatus paymentStatus = PaymentStatus.PENDING;

    @Column(name = "estimated_delivery_time")
    private Integer estimatedDeliveryTime;

    @Column(name = "delivery_address", length = 500)
    private String deliveryAddress;

    @Column(name = "order_notes", length = 500)
    private String orderNotes;

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @Column(name = "delivered_at")
    private LocalDateTime deliveredAt;

    // ============= Operação =============

    // Número sequencial do dia no restaurante (vira o código curto #0042 da cozinha e da comanda)
    @Column(name = "daily_number")
    private Integer dailyNumber;

    @Column(name = "display_code", length = 10)
    private String displayCode;

    // Prazo para o restaurante aceitar (modo MANUAL); depois disso o pedido é cancelado automaticamente
    @Column(name = "accept_deadline")
    private LocalDateTime acceptDeadline;

    @Column(name = "accepted_at")
    private LocalDateTime acceptedAt;

    @Column(name = "ready_at")
    private LocalDateTime readyAt;

    @Column(name = "dispatched_at")
    private LocalDateTime dispatchedAt;

    @Column(name = "cancelled_at")
    private LocalDateTime cancelledAt;

    @Enumerated(EnumType.STRING)
    @Column(name = "cancelled_by", length = 12)
    private CancelledBy cancelledBy;

    @Column(name = "cancellation_reason", length = 500)
    private String cancellationReason;

    // Pagamento em dinheiro: valor que o cliente vai entregar (para o troco)
    @Column(name = "change_for", precision = 10, scale = 2)
    private BigDecimal changeFor;

    // Origem do pedido (nulo nos pedidos anteriores ao campo = app)
    @Enumerated(EnumType.STRING)
    @Column(name = "channel", length = 12)
    private OrderChannel channel;

    // Entrega ou retirada na loja (nulo nos pedidos anteriores ao campo = entrega)
    @Enumerated(EnumType.STRING)
    @Column(name = "fulfillment", length = 12)
    private FulfillmentType fulfillment;

    public OrderChannel channelOrDefault() {
        return channel != null ? channel : OrderChannel.APP;
    }

    public FulfillmentType fulfillmentOrDefault() {
        return fulfillment != null ? fulfillment : FulfillmentType.DELIVERY;
    }

    /** Retirada na loja: não passa pelo despacho nem por rotas */
    public boolean isPickup() {
        return fulfillment == FulfillmentType.PICKUP;
    }

    // Snapshots do cliente e do endereço no momento do pedido
    @Column(name = "customer_name", length = 100)
    private String customerName;

    @Column(name = "customer_phone", length = 20)
    private String customerPhone;

    @Column(name = "delivery_latitude")
    private Double deliveryLatitude;

    @Column(name = "delivery_longitude")
    private Double deliveryLongitude;

    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "restaurant_id")
    private Restaurant restaurant;

    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "delivery_person_id")
    private DeliveryPerson deliveryPerson;

    // ============= Rotas =============

    // Bairro do endereço de entrega (para agrupar entregas)
    @Column(name = "delivery_neighborhood", length = 100)
    private String deliveryNeighborhood;

    // Previsão de ficar pronto: aceite + tempo médio de preparo da loja
    @Column(name = "expected_ready_at")
    private LocalDateTime expectedReadyAt;

    // Liberado para chamar entregador (com rotas ligadas, o planejador libera perto de ficar pronto)
    @Column(name = "dispatch_released_at")
    private LocalDateTime dispatchReleasedAt;

    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "route_id")
    private DeliveryRoute route;

    // Posição na rota (1 = primeira entrega)
    @Column(name = "route_sequence")
    private Integer routeSequence;

    // A loja separou o pedido de uma rota: sai sozinho
    @Column(name = "solo_dispatch")
    private Boolean soloDispatch;

    public boolean isSoloDispatch() {
        return Boolean.TRUE.equals(soloDispatch);
    }

    // Acerto do caixa que fechou este pedido com o entregador (nulo = ainda não acertado)
    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "settlement_id")
    private CourierSettlement settlement;

    // Entregador da equipe própria da loja (sem o app); exclusivo com deliveryPerson
    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "staff_courier_id")
    private StaffCourier staffCourier;

    // ============= Entrega pelo entregador do app =============

    // Valor do entregador pela tabela da associação dele (fixado no aceite da oferta)
    @Column(name = "courier_fee", precision = 10, scale = 2)
    private BigDecimal courierFee;

    // Associação do entregador no momento da entrega (base dos relatórios; não muda se ele trocar de associação)
    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "courier_organization_id")
    private Organization courierOrganization;

    // Distância em linha reta do restaurante até o cliente
    @Column(name = "delivery_distance_km")
    private Double deliveryDistanceKm;

    // Parte do valor do entregador assumida pelo restaurante (quando a taxa cobrada é menor)
    @Column(name = "restaurant_delivery_subsidy", precision = 10, scale = 2)
    private BigDecimal restaurantDeliverySubsidy;

    @Column(name = "assigned_at")
    private LocalDateTime assignedAt;

    @Column(name = "picked_up_at")
    private LocalDateTime pickedUpAt;

    // Quando a entrega foi encerrada para o entregador (entregue ou cancelada): liberação e contadores feitos
    @Column(name = "courier_settled_at")
    private LocalDateTime courierSettledAt;

    // Desde quando o pedido espera um entregador sem nenhum disponível
    @Column(name = "searching_courier_since")
    private LocalDateTime searchingCourierSince;

    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<OrderItem> items = new ArrayList<>();

    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<OrderTracking> trackings = new ArrayList<>();

    // Ocorrências relatadas pelo entregador, da mais antiga para a mais nova
    @OneToMany(mappedBy = "order", fetch = FetchType.LAZY)
    @OrderBy("createdAt ASC")
    private List<OrderIncident> incidents = new ArrayList<>();

    // Constructors
    public Order(User user, Restaurant restaurant, BigDecimal subtotal, BigDecimal deliveryFee, 
                PaymentMethod paymentMethod, String deliveryAddress) {
        this.user = user;
        this.restaurant = restaurant;
        this.subtotal = subtotal;
        this.deliveryFee = deliveryFee;
        this.totalAmount = subtotal.add(deliveryFee);
        this.paymentMethod = paymentMethod;
        this.deliveryAddress = deliveryAddress;
        this.orderNumber = generateOrderNumber();
        this.orderDate = LocalDateTime.now();
    }

    private String generateOrderNumber() {
        return "ORD-" + System.currentTimeMillis();
    }

    public enum PaymentMethod {
        CREDIT_CARD, DEBIT_CARD, PIX, CASH, FOOD_VOUCHER
    }

    public enum PaymentStatus {
        PENDING, PROCESSING, PAID, FAILED, REFUNDED
    }
}
