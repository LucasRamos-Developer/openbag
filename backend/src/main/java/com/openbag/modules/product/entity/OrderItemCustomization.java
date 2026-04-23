package com.openbag.modules.product.entity;

import com.openbag.modules.order.entity.OrderItem;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * OrderItemCustomization - Customizações aplicadas a um item específico do pedido
 */
@Entity
@Table(name = "order_item_customizations")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class OrderItemCustomization {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_item_id", nullable = false)
    private OrderItem orderItem;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customization_option_id", nullable = false)
    private CustomizationOption customizationOption;

    @Column(name = "price_at_purchase", precision = 10, scale = 2, nullable = false)
    private BigDecimal priceAtPurchase;

    @Column(name = "option_name", length = 100, nullable = false)
    private String optionName;

    @Column(name = "group_name", length = 100, nullable = false)
    private String groupName;
}
