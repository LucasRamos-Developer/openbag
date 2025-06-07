package com.openbag.entity;

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

@Entity
@Table(name = "products")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Product {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank
    @Size(max = 100)
    private String name;

    @Size(max = 500)
    private String description;

    @NotNull
    @Column(precision = 10, scale = 2)
    private BigDecimal price;

    @Column(name = "promotional_price", precision = 10, scale = 2)
    private BigDecimal promotionalPrice;

    @Column(name = "image_url")
    private String imageUrl;

    @Column(name = "is_available")
    private boolean isAvailable = true;

    @Column(name = "is_active")
    private boolean isActive = true;

    @Column(name = "preparation_time")
    private Integer preparationTime;

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "restaurant_id")
    private Restaurant restaurant;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private Category category;

    @OneToMany(mappedBy = "product", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<OrderItem> orderItems = new ArrayList<>();

    public Product(String name, String description, BigDecimal price, Restaurant restaurant, Category category) {
        this.name = name;
        this.description = description;
        this.price = price;
        this.restaurant = restaurant;
        this.category = category;
    }

    public BigDecimal getCurrentPrice() {
        return promotionalPrice != null ? promotionalPrice : price;
    }
}
