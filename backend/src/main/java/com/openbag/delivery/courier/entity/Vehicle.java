package com.openbag.delivery.courier.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Veículo do entregador. Ele pode ter vários e escolhe qual está usando ({@link DeliveryPerson#getActiveVehicle()}).
 * Veículos removidos são arquivados para manter o histórico das entregas.
 */
@Entity
@Table(name = "vehicles", indexes = @Index(name = "idx_vehicles_delivery_person", columnList = "delivery_person_id"))
@Getter
@Setter
@NoArgsConstructor
public class Vehicle {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "delivery_person_id", nullable = false)
    private DeliveryPerson deliveryPerson;

    @Enumerated(EnumType.STRING)
    @Column(name = "type", length = 20, nullable = false)
    private VehicleType type;

    @Column(name = "plate", length = 20)
    private String plate;

    @Column(name = "model", length = 50)
    private String model;

    @Column(name = "color", length = 30)
    private String color;

    @Column(name = "photo_url")
    private String photoUrl;

    @Column(name = "archived", nullable = false)
    private boolean archived = false;

    // Custos informados pelo entregador, todos opcionais, para o resultado estimado da aba Ganhos
    @Column(name = "fuel_consumption_km_per_liter", precision = 6, scale = 2)
    private BigDecimal fuelConsumptionKmPerLiter;

    @Column(name = "fuel_price_per_liter", precision = 6, scale = 2)
    private BigDecimal fuelPricePerLiter;

    @Column(name = "maintenance_per_km", precision = 6, scale = 3)
    private BigDecimal maintenancePerKm;

    @Column(name = "depreciation_per_km", precision = 6, scale = 3)
    private BigDecimal depreciationPerKm;

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    /** Algum custo informado */
    public boolean hasCosts() {
        return fuelConsumptionKmPerLiter != null || fuelPricePerLiter != null || maintenancePerKm != null
                || depreciationPerKm != null;
    }

    public boolean isMotorized() {
        return type == VehicleType.MOTORCYCLE || type == VehicleType.CAR;
    }
}
