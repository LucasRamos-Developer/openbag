package com.openbag.modules.product.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * CustomizationOption - Opção individual dentro de um grupo de customização
 * Exemplos: "Pequeno", "Médio", "Grande", "Bacon Extra +R$4.50"
 */
@Entity
@Table(name = "customization_options")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CustomizationOption {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "Nome da opção é obrigatório")
    @Size(max = 100)
    @Column(nullable = false)
    private String name;

    @NotNull
    @Column(name = "price_modifier", precision = 10, scale = 2, nullable = false)
    private BigDecimal priceModifier = BigDecimal.ZERO;

    @Column(name = "is_available")
    private boolean isAvailable = true;

    @Column(name = "display_order")
    private Integer displayOrder = 0;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customization_group_id", nullable = false)
    private CustomizationGroup customizationGroup;

    public CustomizationOption(String name, BigDecimal priceModifier, CustomizationGroup group) {
        this.name = name;
        this.priceModifier = priceModifier;
        this.customizationGroup = group;
    }
}
