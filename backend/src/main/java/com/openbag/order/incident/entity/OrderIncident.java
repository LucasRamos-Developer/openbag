package com.openbag.order.incident.entity;

import com.openbag.association.core.entity.Organization;
import com.openbag.delivery.courier.entity.DeliveryPerson;
import com.openbag.order.core.entity.Order;
import com.openbag.restaurant.store.entity.Restaurant;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * Ocorrência relatada pelo entregador durante a entrega (pedido não pronto, cliente não localizado...).
 * Guarda a loja e a associação do entregador no momento, para o relatório da cooperativa não depender de
 * quem ficou com o pedido depois.
 */
@Entity
@Table(name = "order_incidents", indexes = {
        @Index(name = "idx_order_incident_order", columnList = "order_id"),
        @Index(name = "idx_order_incident_organization", columnList = "organization_id, created_at")
})
@Getter
@Setter
@NoArgsConstructor
public class OrderIncident {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "restaurant_id", nullable = false)
    private Restaurant restaurant;

    /** Associação do entregador quando relatou (nula para quem não está numa associação) */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "organization_id")
    private Organization organization;

    /** Quem relatou */
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "delivery_person_id", nullable = false)
    private DeliveryPerson deliveryPerson;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private IncidentType type;

    @Column(length = 300)
    private String note;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
}
