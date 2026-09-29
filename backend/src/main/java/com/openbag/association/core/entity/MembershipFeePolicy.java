package com.openbag.association.core.entity;

import com.openbag.enums.MembershipFeeMode;
import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Como a associação cobra a mensalidade dos cooperados:
 * <ul>
 *   <li>{@code FIXED}: o mesmo valor todo mês;</li>
 *   <li>{@code PERCENTAGE}: um percentual do que o cooperado ganhou no mês, até o teto ({@code monthlyCap});
 *       passando do teto não cobra mais nada, só os adicionais.</li>
 * </ul>
 * A fatura vence no dia {@code dueDay} do mês seguinte.
 */
@Embeddable
@Data
@NoArgsConstructor
@AllArgsConstructor
public class MembershipFeePolicy {

    public static final int DEFAULT_DUE_DAY = 10;

    @Enumerated(EnumType.STRING)
    @Column(name = "fee_mode", length = 20)
    private MembershipFeeMode mode;

    @Column(name = "fee_fixed_amount", precision = 10, scale = 2)
    private BigDecimal fixedAmount;

    /** Percentual dos ganhos (5 = 5%) */
    @Column(name = "fee_percentage", precision = 5, scale = 2)
    private BigDecimal percentage;

    /** Teto da mensalidade percentual (nulo = sem teto) */
    @Column(name = "fee_monthly_cap", precision = 10, scale = 2)
    private BigDecimal monthlyCap;

    @Column(name = "fee_due_day")
    private Integer dueDay;

    public boolean isConfigured() {
        return mode == MembershipFeeMode.FIXED ? fixedAmount != null
                : mode == MembershipFeeMode.PERCENTAGE && percentage != null;
    }

    public int getDueDayOrDefault() {
        return dueDay != null ? dueDay : DEFAULT_DUE_DAY;
    }
}
