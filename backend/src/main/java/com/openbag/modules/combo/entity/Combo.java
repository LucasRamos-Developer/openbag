package com.openbag.modules.combo.entity;

import com.openbag.modules.restaurant.entity.Restaurant;
import com.openbag.modules.product.entity.Category;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
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

/**
 * Combo - Pacote promocional com múltiplos produtos
 * Exemplo: "Combo Executivo: Prato Principal + Bebida + Sobremesa por R$ 35,00"
 */
@Entity
@Table(name = "combos")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Combo {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "Nome do combo é obrigatório")
    @Size(max = 200)
    @Column(nullable = false)
    private String name;

    @Column(length = 1000)
    private String description;

    @NotNull(message = "Preço do combo é obrigatório")
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal price;

    @Column(name = "image_url", length = 500)
    private String imageUrl;

    @Column(name = "is_available")
    private boolean isAvailable = true;

    @Column(name = "is_active")
    private boolean isActive = true;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "restaurant_id", nullable = false)
    private Restaurant restaurant;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private Category category;

    @OneToMany(mappedBy = "combo", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<ComboItem> comboItems = new ArrayList<>();

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    /**
     * Calcular economia do combo (soma dos produtos individuais - preço do combo)
     */
    public BigDecimal calculateSavings() {
        BigDecimal totalIndividual = comboItems.stream()
                .map(ComboItem::calculateIndividualPrice)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        return totalIndividual.subtract(price);
    }
}
