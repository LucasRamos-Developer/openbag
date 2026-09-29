package com.openbag.delivery.courier.entity;

import com.openbag.enums.ShiftMode;
import com.openbag.restaurant.store.entity.Restaurant;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * Turno do entregador: do "ficar online" (FREE) ou do check-in no restaurante (FIXED) até sair
 */
@Entity
@Table(name = "courier_shifts", indexes = {
        @Index(name = "idx_shift_courier", columnList = "delivery_person_id"),
        @Index(name = "idx_shift_restaurant_open", columnList = "restaurant_id, ended_at")
})
@Getter
@Setter
@NoArgsConstructor
public class CourierShift {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "delivery_person_id", nullable = false)
    private DeliveryPerson deliveryPerson;

    @Enumerated(EnumType.STRING)
    @Column(name = "mode", length = 10, nullable = false)
    private ShiftMode mode;

    // Só no turno FIXED
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "restaurant_id")
    private Restaurant restaurant;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "vehicle_id")
    private Vehicle vehicle;

    @Column(name = "started_at", nullable = false)
    private LocalDateTime startedAt;

    @Column(name = "ended_at")
    private LocalDateTime endedAt;

    @Column(name = "start_latitude")
    private Double startLatitude;

    @Column(name = "start_longitude")
    private Double startLongitude;

    @Column(name = "deliveries_count", nullable = false)
    private int deliveriesCount = 0;

    // Última entrega concluída no turno: desempate do rodízio entre fixos (quem está parado há mais tempo)
    @Column(name = "last_delivery_at")
    private LocalDateTime lastDeliveryAt;

    public boolean isOpen() {
        return endedAt == null;
    }
}
