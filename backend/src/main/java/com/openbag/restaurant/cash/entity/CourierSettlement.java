package com.openbag.restaurant.cash.entity;

import com.openbag.restaurant.store.entity.Restaurant;
import com.openbag.modules.user.entity.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import com.openbag.delivery.courier.entity.DeliveryPerson;
import com.openbag.delivery.link.entity.StaffCourier;

/**
 * Acerto do caixa entre a loja e um entregador (do app ou da equipe própria): fecha os pedidos entregues que
 * ainda não tinham acerto. Saldo = dinheiro recebido dos clientes − valor das entregas;
 * positivo = o entregador devolve à loja, negativo = a loja paga ao entregador.
 */
@Entity
@Table(name = "courier_settlements", indexes = @Index(name = "idx_settlement_restaurant", columnList = "restaurant_id, settled_at"))
@Getter
@Setter
@NoArgsConstructor
public class CourierSettlement {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "restaurant_id", nullable = false)
    private Restaurant restaurant;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "delivery_person_id")
    private DeliveryPerson deliveryPerson;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "staff_courier_id")
    private StaffCourier staffCourier;

    @Column(name = "orders_count", nullable = false)
    private int ordersCount;

    @Column(name = "cash_collected", precision = 10, scale = 2, nullable = false)
    private BigDecimal cashCollected;

    @Column(name = "courier_earnings", precision = 10, scale = 2, nullable = false)
    private BigDecimal courierEarnings;

    @Column(name = "balance", precision = 10, scale = 2, nullable = false)
    private BigDecimal balance;

    @Column(name = "settled_at", nullable = false)
    private LocalDateTime settledAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "settled_by")
    private User settledBy;
}
