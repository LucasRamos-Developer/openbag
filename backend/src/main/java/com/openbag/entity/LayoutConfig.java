package com.openbag.entity;

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
    private Restaurant restaurant;

    @NotBlank(message = "Cor primária é obrigatória")
    @Size(max = 7, message = "Cor primária deve ter no máximo 7 caracteres")
    @Column(name = "primary_color", nullable = false, length = 7)
    private String primaryColor;

    @NotBlank(message = "Cor secundária é obrigatória")
    @Size(max = 7, message = "Cor secundária deve ter no máximo 7 caracteres")
    @Column(name = "secondary_color", nullable = false, length = 7)
    private String secondaryColor;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
