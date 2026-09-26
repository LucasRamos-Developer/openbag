package com.openbag.modules.delivery.entity;

import com.openbag.modules.organization.entity.Organization;
import com.openbag.modules.restaurant.entity.Restaurant;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

/**
 * Associação parceira do restaurante (política PARTNERS_ONLY). A parceria é livre: o restaurante adiciona sem aceite.
 * Encerrada quando {@code endedAt} é preenchido; o histórico fica.
 */
@Entity
@Table(name = "restaurant_partnerships",
        indexes = @Index(name = "idx_partnership_restaurant", columnList = "restaurant_id"))
@Getter
@Setter
@NoArgsConstructor
public class RestaurantPartnership {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "restaurant_id", nullable = false)
    private Restaurant restaurant;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "organization_id", nullable = false)
    private Organization organization;

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "ended_at")
    private LocalDateTime endedAt;
}
