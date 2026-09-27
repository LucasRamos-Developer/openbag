package com.openbag.modules.menu.entity;

import com.openbag.modules.restaurant.entity.Restaurant;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

/**
 * Seção do cardápio definida pelo próprio restaurante (ex: Lanches, Bebidas, Promoções).
 * Corresponde a MenuSection do schema.org.
 */
@Entity
@Table(name = "menu_sections", indexes = @Index(name = "idx_menu_section_restaurant", columnList = "restaurant_id, position"))
@Getter
@Setter
@NoArgsConstructor
public class MenuSection {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "restaurant_id", nullable = false)
    private Restaurant restaurant;

    @NotBlank
    @Size(max = 80)
    @Column(nullable = false, length = 80)
    private String name;

    @Size(max = 300)
    @Column(length = 300)
    private String description;

    /** Ícone da seção no cardápio (chave do catálogo do frontend, ex: "lunch_dining") */
    @Size(max = 30)
    @Column(length = 30)
    private String icon;

    @Column(nullable = false)
    private int position = 0;

    @Column(nullable = false)
    private boolean active = true;

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
