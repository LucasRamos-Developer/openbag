package com.openbag.modules.product.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * CustomizationGroup - Grupo de customizações para um produto
 * Exemplos: "Tamanho", "Adicionais", "Sabor", "Proteína"
 */
@Entity
@Table(name = "customization_groups")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CustomizationGroup {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "Nome do grupo é obrigatório")
    @Size(max = 100)
    @Column(nullable = false)
    private String name;

    @Column(name = "is_required")
    private boolean isRequired = false;

    @Column(name = "min_selections")
    private Integer minSelections = 0;

    @Column(name = "max_selections")
    private Integer maxSelections = 1;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id", nullable = false)
    private Product product;

    @OneToMany(mappedBy = "customizationGroup", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<CustomizationOption> options = new ArrayList<>();

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    public CustomizationGroup(String name, boolean isRequired, Product product) {
        this.name = name;
        this.isRequired = isRequired;
        this.product = product;
    }
}
