package com.openbag.restaurant.store.entity;

import com.openbag.enums.RestaurantThemePreset;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "layout_configs")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class LayoutConfig {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "restaurant_id", nullable = false, unique = true)
    @com.fasterxml.jackson.annotation.JsonIgnore
    private Restaurant restaurant;

    @NotBlank(message = "Cor primária é obrigatória")
    @Size(max = 7, message = "Cor primária deve ter no máximo 7 caracteres")
    @Column(name = "primary_color", nullable = false, length = 7)
    private String primaryColor;

    @NotBlank(message = "Cor secundária é obrigatória")
    @Size(max = 7, message = "Cor secundária deve ter no máximo 7 caracteres")
    @Column(name = "secondary_color", nullable = false, length = 7)
    private String secondaryColor;

    /** Tema da página pública; nulo em registros antigos (vale o padrão) */
    @Enumerated(EnumType.STRING)
    @Column(name = "theme_preset", length = 20)
    private RestaurantThemePreset themePreset;

    /** Cor da marca opcional (#RRGGBB) que substitui a cor principal do tema */
    @Column(name = "brand_color", length = 7)
    private String brandColor;

    /** Frase de destaque exibida no banner */
    @Size(max = 80, message = "O slogan deve ter no máximo 80 caracteres")
    @Column(name = "slogan", length = 80)
    private String slogan;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    public RestaurantThemePreset getThemePreset() {
        return themePreset != null ? themePreset : RestaurantThemePreset.DEFAULT;
    }

    /** Cor principal efetiva: a da marca, se houver, senão a do tema */
    public String getEffectivePrimaryColor() {
        return brandColor != null ? brandColor : getThemePreset().getPrimaryHex();
    }

    /**
     * Aplica a aparência escolhida. As colunas antigas primary/secondary (NOT NULL) continuam
     * preenchidas com a cor efetiva para quem ainda as lê.
     */
    public void applyAppearance(RestaurantThemePreset preset, String brandColor, String slogan) {
        this.themePreset = preset != null ? preset : RestaurantThemePreset.DEFAULT;
        this.brandColor = brandColor == null || brandColor.isBlank() ? null : brandColor.toUpperCase();
        this.slogan = slogan == null || slogan.isBlank() ? null : slogan.trim();
        this.primaryColor = getEffectivePrimaryColor();
        this.secondaryColor = getEffectivePrimaryColor();
    }
}
