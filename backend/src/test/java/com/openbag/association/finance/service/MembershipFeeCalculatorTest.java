package com.openbag.association.finance.service;

import com.openbag.association.finance.entity.AddonPricing;
import com.openbag.association.finance.entity.InvoiceLineType;
import com.openbag.association.core.entity.MembershipFeeMode;
import com.openbag.association.finance.entity.AddonPlan;
import com.openbag.association.finance.entity.MemberInvoiceLine;
import com.openbag.association.core.entity.MembershipFeePolicy;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class MembershipFeeCalculatorTest {

    private static MembershipFeePolicy percentage(String pct, String cap) {
        return new MembershipFeePolicy(MembershipFeeMode.PERCENTAGE, null, new BigDecimal(pct),
                cap != null ? new BigDecimal(cap) : null, 10);
    }

    private static AddonPlan insurance() {
        AddonPlan plan = new AddonPlan();
        plan.setName("Seguro de vida");
        plan.setPricing(AddonPricing.PERCENT_OF_FEE);
        plan.setValue(new BigDecimal("10"));
        return plan;
    }

    @Test
    void percentageOfTheEarningsUntilTheCap() {
        MembershipFeePolicy policy = percentage("5", "100.00");

        assertThat(MembershipFeeCalculator.fee(policy, new BigDecimal("1200.00"))).isEqualByComparingTo("60.00");
        // 5% de 3.000 = 150, mas o teto é 100: depois do teto não cobra mais nada
        assertThat(MembershipFeeCalculator.fee(policy, new BigDecimal("3000.00"))).isEqualByComparingTo("100.00");
        assertThat(MembershipFeeCalculator.fee(policy, BigDecimal.ZERO)).isEqualByComparingTo("0.00");
    }

    @Test
    void percentageWithoutCapHasNoLimit() {
        assertThat(MembershipFeeCalculator.fee(percentage("5", null), new BigDecimal("3000.00")))
                .isEqualByComparingTo("150.00");
    }

    @Test
    void fixedFeeIgnoresTheEarnings() {
        MembershipFeePolicy policy = new MembershipFeePolicy(MembershipFeeMode.FIXED, new BigDecimal("80.00"), null, null, 10);

        assertThat(MembershipFeeCalculator.fee(policy, new BigDecimal("5000"))).isEqualByComparingTo("80.00");
        assertThat(MembershipFeeCalculator.fee(policy, BigDecimal.ZERO)).isEqualByComparingTo("80.00");
    }

    @Test
    void lifeInsuranceAddsTenPercentOfTheFeeAndTheCapDoesNotApplyToAddons() {
        List<MemberInvoiceLine> lines = MembershipFeeCalculator.lines(percentage("5", "100.00"),
                new BigDecimal("3000.00"), List.of(insurance()), new BigDecimal("15.00"));

        assertThat(lines).extracting(MemberInvoiceLine::getType)
                .containsExactly(InvoiceLineType.FEE, InvoiceLineType.ADDON, InvoiceLineType.SOLIDARITY);
        assertThat(lines.get(1).getAmount()).isEqualByComparingTo("10.00");
        // 100 (mensalidade no teto) + 10 (seguro) + 15 (caixinha)
        assertThat(MembershipFeeCalculator.total(lines)).isEqualByComparingTo("125.00");
    }

    @Test
    void fixedAddonAndZeroLinesLeftOut() {
        AddonPlan fixed = new AddonPlan();
        fixed.setName("Oficina parceira");
        fixed.setPricing(AddonPricing.FIXED);
        fixed.setValue(new BigDecimal("20.00"));

        List<MemberInvoiceLine> lines = MembershipFeeCalculator.lines(percentage("5", "100.00"), BigDecimal.ZERO,
                List.of(insurance(), fixed), null);

        // Sem ganhos: mensalidade zero, seguro (10% de zero) fica de fora, o fixo continua
        assertThat(lines).extracting(MemberInvoiceLine::getDescription)
                .containsExactly("Mensalidade (5% dos ganhos, com teto)", "Oficina parceira");
        assertThat(MembershipFeeCalculator.total(lines)).isEqualByComparingTo("20.00");
    }
}
