package com.openbag.modules.combo.entity;

import com.openbag.modules.product.entity.Product;
import jakarta.persistence.*;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * ComboItem - Produto individual incluído em um combo
 * Exemplo: "1x Hambúrguer Clássico", "1x Refrigerante Lata"
 */
@Entity
@Table(name = "combo_items")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ComboItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotNull
    @Min(1)
    @Column(nullable = false)
    private Integer quantity = 1;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "combo_id", nullable = false)
    private Combo combo;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id", nullable = false)
    private Product product;

    /**
     * Preço unitário do produto no momento da criação do combo (snapshot)
     */
    @Column(name = "unit_price_snapshot", precision = 10, scale = 2)
    private BigDecimal unitPriceSnapshot;

    /**
     * Calcular preço total deste item se comprado individualmente
     */
    public BigDecimal calculateIndividualPrice() {
        if (unitPriceSnapshot != null) {
            return unitPriceSnapshot.multiply(BigDecimal.valueOf(quantity));
        }
        return product.getCurrentPrice().multiply(BigDecimal.valueOf(quantity));
    }
}
