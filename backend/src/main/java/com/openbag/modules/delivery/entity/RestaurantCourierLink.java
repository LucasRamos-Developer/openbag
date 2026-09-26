package com.openbag.modules.delivery.entity;

import com.openbag.enums.CourierLinkStatus;
import com.openbag.enums.LinkRequester;
import com.openbag.modules.restaurant.entity.Restaurant;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

/**
 * Entregador fixo de um restaurante. Com o vínculo ACTIVE ele pode fazer check-in lá e, durante o turno,
 * só recebe pedidos daquele restaurante.
 */
@Entity
@Table(name = "restaurant_courier_links", indexes = {
        @Index(name = "idx_courier_link_restaurant", columnList = "restaurant_id"),
        @Index(name = "idx_courier_link_courier", columnList = "delivery_person_id")
})
@Getter
@Setter
@NoArgsConstructor
public class RestaurantCourierLink {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "restaurant_id", nullable = false)
    private Restaurant restaurant;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "delivery_person_id", nullable = false)
    private DeliveryPerson deliveryPerson;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", length = 20, nullable = false)
    private CourierLinkStatus status = CourierLinkStatus.PENDING;

    @Enumerated(EnumType.STRING)
    @Column(name = "requested_by", length = 20, nullable = false)
    private LinkRequester requestedBy;

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "decided_at")
    private LocalDateTime decidedAt;

    @Column(name = "ended_at")
    private LocalDateTime endedAt;
}
