package com.openbag.association.finance.dto;

import com.openbag.association.core.entity.MembershipFeeMode;
import com.openbag.association.core.entity.MembershipFeePolicy;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

/**
 * Cobrança da mensalidade: valor fixo ou percentual dos ganhos até o teto
 */
public record FeePolicyDTO(
        @NotNull(message = "Escolha como cobrar a mensalidade") MembershipFeeMode mode,
        @DecimalMin(value = "0.00", message = "O valor não pode ser negativo") BigDecimal fixedAmount,
        @DecimalMin(value = "0.00", message = "O percentual não pode ser negativo")
        @DecimalMax(value = "100.00", message = "O percentual vai até 100%") BigDecimal percentage,
        @DecimalMin(value = "0.00", message = "O teto não pode ser negativo") BigDecimal monthlyCap,
        @Min(value = 1, message = "Dia entre 1 e 28") @Max(value = 28, message = "Dia entre 1 e 28") Integer dueDay,
        boolean configured) {

    public static FeePolicyDTO from(MembershipFeePolicy policy) {
        if (policy == null) {
            return new FeePolicyDTO(null, null, null, null, MembershipFeePolicy.DEFAULT_DUE_DAY, false);
        }
        return new FeePolicyDTO(policy.getMode(), policy.getFixedAmount(), policy.getPercentage(),
                policy.getMonthlyCap(), policy.getDueDayOrDefault(), policy.isConfigured());
    }

    public MembershipFeePolicy toEntity() {
        boolean fixed = mode == MembershipFeeMode.FIXED;
        return new MembershipFeePolicy(mode, fixed ? fixedAmount : null, fixed ? null : percentage,
                fixed ? null : monthlyCap, dueDay != null ? dueDay : MembershipFeePolicy.DEFAULT_DUE_DAY);
    }
}
