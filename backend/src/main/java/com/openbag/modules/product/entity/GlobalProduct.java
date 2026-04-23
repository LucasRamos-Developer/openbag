package com.openbag.modules.product.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

/**
 * GlobalProduct - Catálogo global de produtos industrializados
 * Gerenciado por ADMIN, produtos compartilhados entre todos os restaurantes
 */
@Entity
@Table(name = "global_products")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class GlobalProduct {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "Código de barras é obrigatório")
    @Size(max = 50)
    @Column(name = "barcode", unique = true, nullable = false)
    private String barcode;

    @NotBlank(message = "Nome do produto é obrigatório")
    @Size(max = 200)
    @Column(nullable = false)
    private String name;

    @Size(max = 100)
    private String brand;

    @Size(max = 1000)
    private String description;

    @Column(name = "default_image_url")
    private String defaultImageUrl;

    @Column(name = "is_active")
    private boolean isActive = true;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private Category category;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    public GlobalProduct(String barcode, String name, String brand, Category category) {
        this.barcode = barcode;
        this.name = name;
        this.brand = brand;
        this.category = category;
    }
}
