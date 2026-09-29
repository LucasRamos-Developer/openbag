package com.openbag.modules.delivery.entity;

import com.openbag.modules.user.entity.User;
import com.openbag.modules.organization.entity.Organization;
import com.openbag.modules.order.entity.Order;
import com.openbag.enums.CourierWorkStatus;
import com.openbag.enums.VehicleType;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "delivery_persons")
// Grava só as colunas alteradas: salvar a situação não reescreve a posição, que o ping atualiza à parte
@org.hibernate.annotations.DynamicUpdate
@Data
@NoArgsConstructor
@AllArgsConstructor
public class DeliveryPerson {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Trava otimista da situação do entregador; a posição é gravada à parte e não muda a versão */
    @Version
    @lombok.EqualsAndHashCode.Exclude
    private Long version;

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

    // ============= Perfil público =============

    // Identificador do perfil público (/e/{slug}), usado também no QR code da placa de verificação
    @Column(name = "slug", length = 80, unique = true)
    private String slug;

    @Size(max = 500)
    @Column(name = "bio", length = 500)
    private String bio;

    @Column(name = "photo_url")
    private String photoUrl;

    @Column(name = "show_work_history")
    private Boolean showWorkHistory;

    @ElementCollection
    @CollectionTable(name = "delivery_person_social_links", joinColumns = @JoinColumn(name = "delivery_person_id"))
    @OrderColumn(name = "position")
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    private List<CourierSocialLink> socialLinks = new ArrayList<>();

    // Veículo em uso; os campos vehicle* acima espelham este veículo (legado usado pelo painel da associação)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "active_vehicle_id")
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    private Vehicle activeVehicle;

    // ============= Trabalho =============

    @Enumerated(EnumType.STRING)
    @Column(name = "work_status", length = 10)
    private CourierWorkStatus workStatus;

    @Column(name = "last_latitude")
    private Double lastLatitude;

    @Column(name = "last_longitude")
    private Double lastLongitude;

    // Último envio de localização; online sem sinal há muito tempo não recebe ofertas
    @Column(name = "last_seen_at")
    private LocalDateTime lastSeenAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "current_shift_id")
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    private CourierShift currentShift;

    public CourierWorkStatus getWorkStatus() {
        return workStatus != null ? workStatus : CourierWorkStatus.OFFLINE;
    }

    // Pedidos que o entregador está responsável por entregar
    @OneToMany(mappedBy = "deliveryPerson", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    private List<Order> orders = new ArrayList<>();

    public boolean isShowWorkHistory() {
        return showWorkHistory == null || showWorkHistory;
    }

    /**
     * Copia os dados do veículo em uso para os campos legados
     */
    public void useVehicle(Vehicle vehicle) {
        this.activeVehicle = vehicle;
        this.vehicleType = vehicle != null ? vehicle.getType() : null;
        this.vehiclePlate = vehicle != null ? vehicle.getPlate() : null;
        this.vehicleModel = vehicle != null ? vehicle.getModel() : null;
        this.vehicleColor = vehicle != null ? vehicle.getColor() : null;
    }
}
