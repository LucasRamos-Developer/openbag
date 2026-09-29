package com.openbag.modules.delivery.entity;

import com.openbag.enums.DeliveryOfferStatus;
import com.openbag.modules.order.entity.Order;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Oferta de um pedido a um entregador. Ele tem até {@code expiresAt} para aceitar; recusada ou expirada,
 * o pedido é oferecido ao próximo.
 */
@Entity
@Table(name = "delivery_offers", indexes = {
        @Index(name = "idx_offer_order", columnList = "order_id"),
        @Index(name = "idx_offer_courier_status", columnList = "delivery_person_id, status"),
        @Index(name = "idx_offer_status_expires", columnList = "status, expires_at")
})
@Getter
@Setter
@NoArgsConstructor
public class DeliveryOffer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Trava otimista: aceite, recusa e expiração da mesma oferta nunca valem juntos */
    @Version
    private Long version;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "delivery_person_id", nullable = false)
    private DeliveryPerson deliveryPerson;

    // Oferta de rota: vale para todos os pedidos da rota (order = pedido líder); nulo = pedido sozinho
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "route_id")
    private DeliveryRoute route;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", length = 20, nullable = false)
    private DeliveryOfferStatus status = DeliveryOfferStatus.PENDING;

    // Do entregador até o restaurante (null para fixo em check-in)
    @Column(name = "pickup_distance_km")
    private Double pickupDistanceKm;

    // Do restaurante até o cliente
    @Column(name = "delivery_distance_km")
    private Double deliveryDistanceKm;

    @Column(name = "courier_fee", precision = 10, scale = 2, nullable = false)
    private BigDecimal courierFee;

    @Column(name = "score")
    private Double score;

    @Column(name = "offered_at", nullable = false)
    private LocalDateTime offeredAt;

    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    @Column(name = "responded_at")
    private LocalDateTime respondedAt;
}
