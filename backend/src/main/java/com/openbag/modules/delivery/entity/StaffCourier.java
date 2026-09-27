package com.openbag.modules.delivery.entity;

import com.openbag.modules.restaurant.entity.Restaurant;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Entregador da equipe própria do restaurante, sem o app: a loja atribui o pedido e marca a saída e a entrega.
 * Removido = desativado (o histórico dos pedidos e do caixa continua apontando para ele).
 */
@Entity
@Table(name = "staff_couriers", indexes = @Index(name = "idx_staff_courier_restaurant", columnList = "restaurant_id"))
@Getter
@Setter
@NoArgsConstructor
public class StaffCourier {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "restaurant_id", nullable = false)
    private Restaurant restaurant;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(length = 20)
    private String phone;

    // Valor pago por entrega; nulo = a taxa de entrega cobrada do cliente
    @Column(name = "fee_per_delivery", precision = 10, scale = 2)
    private BigDecimal feePerDelivery;

    @Column(nullable = false)
    private boolean active = true;

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;
}
