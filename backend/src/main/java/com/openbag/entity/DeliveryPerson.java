package com.openbag.entity;

import com.openbag.enums.VehicleType;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
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
@Table(name = "delivery_persons")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class DeliveryPerson {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", unique = true)
    private User user;

    @NotBlank
    @Size(max = 20)
    @Column(name = "document_number", unique = true)
    private String documentNumber; // CPF

    @NotBlank
    @Size(max = 20)
    @Column(name = "driver_license", unique = true)
    private String driverLicense; // CNH

    @Enumerated(EnumType.STRING)
    @Column(name = "vehicle_type")
    private VehicleType vehicleType;

    @Size(max = 20)
    @Column(name = "vehicle_plate")
    private String vehiclePlate;

    @Size(max = 50)
    @Column(name = "vehicle_model")
    private String vehicleModel;

    @Size(max = 30)
    @Column(name = "vehicle_color")
    private String vehicleColor;

    @Column(name = "is_available")
    private boolean isAvailable = true;

    @Column(name = "is_active")
    private boolean isActive = true;

    @Column(name = "rating", precision = 3, scale = 2)
    private BigDecimal rating = BigDecimal.ZERO;

    @Column(name = "total_deliveries")
    private Integer totalDeliveries = 0;

    @Column(name = "total_reviews")
    private Integer totalReviews = 0;

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // Organização à qual o entregador pode pertencer (opcional)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "organization_id")
    private Organization organization;

    // Pedidos que o entregador está responsável por entregar
    @OneToMany(mappedBy = "deliveryPerson", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Order> orders = new ArrayList<>();
}
