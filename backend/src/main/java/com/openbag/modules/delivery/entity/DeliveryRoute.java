package com.openbag.modules.delivery.entity;

import com.openbag.enums.RouteOrigin;
import com.openbag.enums.RouteStatus;
import com.openbag.modules.order.entity.Order;
import com.openbag.modules.restaurant.entity.Restaurant;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.locationtech.jts.geom.LineString;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/**
 * Rota de entrega: pedidos da mesma loja levados juntos por um entregador, na ordem de {@code Order.routeSequence}.
 * O primeiro da ordem é o "pedido líder": as ofertas da rota ficam registradas nele.
 */
@Entity
@Table(name = "delivery_routes", indexes = @Index(name = "idx_route_restaurant_status", columnList = "restaurant_id, status"))
@Getter
@Setter
@NoArgsConstructor
public class DeliveryRoute {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "restaurant_id", nullable = false)
    private Restaurant restaurant;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private RouteStatus status = RouteStatus.PLANNED;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private RouteOrigin origin = RouteOrigin.AUTO;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "delivery_person_id")
    private DeliveryPerson deliveryPerson;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "staff_courier_id")
    private StaffCourier staffCourier;

    @Column(name = "total_distance_km")
    private Double totalDistanceKm;

    // Quanto a rota economiza em relação a uma viagem por pedido (com a volta à loja)
    @Column(name = "saved_distance_km")
    private Double savedDistanceKm;

    // Quando o entregador será chamado (rota ainda montando)
    @Column(name = "dispatch_at")
    private LocalDateTime dispatchAt;

    // Aviso para a loja, ex.: "Aguardando #0012 ficar pronto (~4 min) para sair junto"
    @Column(name = "wait_reason", length = 200)
    private String waitReason;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "dispatched_at")
    private LocalDateTime dispatchedAt;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    // Caminho pelas ruas (loja → paradas na ordem), calculado pelo OSRM; SRID 4326 (x = lng, y = lat)
    @Column(name = "street_path", columnDefinition = "geometry(LineString,4326)")
    private LineString streetPath;

    // Paradas usadas no cálculo do caminho; se mudarem, o caminho é refeito
    @Column(name = "street_path_key", columnDefinition = "text")
    private String streetPathKey;

    @OneToMany(mappedBy = "route", fetch = FetchType.LAZY)
    private List<Order> orders = new ArrayList<>();

    /** Pedidos da rota na ordem de entrega */
    public List<Order> sortedOrders() {
        return orders.stream()
                .sorted(Comparator.comparing(Order::getRouteSequence, Comparator.nullsLast(Comparator.naturalOrder())))
                .toList();
    }
}
