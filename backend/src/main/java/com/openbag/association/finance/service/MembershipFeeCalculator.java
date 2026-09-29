package com.openbag.association.finance.service;

import com.openbag.enums.InvoiceLineType;
import com.openbag.enums.MembershipFeeMode;
import com.openbag.association.finance.entity.AddonPlan;
import com.openbag.association.finance.entity.MemberInvoiceLine;
import com.openbag.association.core.entity.MembershipFeePolicy;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;

/**
 * Cálculo da fatura do cooperado. A mensalidade é fixa ou um percentual dos ganhos do mês limitado ao teto
 * (depois do teto não cobra mais nada); os adicionais vêm por cima (o seguro de 10% é 10% da mensalidade);
 * a contribuição para a caixinha solidária é o valor que o próprio cooperado escolheu.
 */
public final class MembershipFeeCalculator {

    private MembershipFeeCalculator() {
    }

    public static BigDecimal fee(MembershipFeePolicy policy, BigDecimal earnings) {
        if (policy == null || !policy.isConfigured()) {
            return BigDecimal.ZERO.setScale(2);
        }
        if (policy.getMode() == MembershipFeeMode.FIXED) {
            return policy.getFixedAmount().setScale(2, RoundingMode.HALF_UP);
        }
        BigDecimal base = earnings != null ? earnings : BigDecimal.ZERO;
        BigDecimal fee = base.multiply(policy.getPercentage()).divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
        BigDecimal cap = policy.getMonthlyCap();
        return cap != null && fee.compareTo(cap) > 0 ? cap.setScale(2, RoundingMode.HALF_UP) : fee;
    }

    /** Itens da fatura: mensalidade, adicionais ativos e contribuição da caixinha (itens zerados ficam de fora) */
    public static List<MemberInvoiceLine> lines(MembershipFeePolicy policy, BigDecimal earnings,
                                                List<AddonPlan> activeAddons, BigDecimal solidarityContribution) {
        List<MemberInvoiceLine> lines = new ArrayList<>();
        BigDecimal fee = fee(policy, earnings);
        lines.add(new MemberInvoiceLine(InvoiceLineType.FEE, feeDescription(policy), fee));
        for (AddonPlan plan : activeAddons) {
            BigDecimal charge = plan.chargeFor(fee);
            if (charge.signum() > 0) {
                lines.add(new MemberInvoiceLine(InvoiceLineType.ADDON, plan.getName(), charge));
            }
        }
        if (solidarityContribution != null && solidarityContribution.signum() > 0) {
            lines.add(new MemberInvoiceLine(InvoiceLineType.SOLIDARITY, "Caixinha solidária",
                    solidarityContribution.setScale(2, RoundingMode.HALF_UP)));
        }
        return lines;
    }

    public static BigDecimal total(List<MemberInvoiceLine> lines) {
        return lines.stream().map(MemberInvoiceLine::getAmount).reduce(BigDecimal.ZERO, BigDecimal::add)
                .setScale(2, RoundingMode.HALF_UP);
    }

    private static String feeDescription(MembershipFeePolicy policy) {
        if (policy == null || !policy.isConfigured()) {
            return "Mensalidade";
        }
        if (policy.getMode() == MembershipFeeMode.FIXED) {
            return "Mensalidade";
        }
        String pct = policy.getPercentage().stripTrailingZeros().toPlainString().replace('.', ',');
        return "Mensalidade (" + pct + "% dos ganhos" + (policy.getMonthlyCap() != null ? ", com teto" : "") + ")";
    }
}
