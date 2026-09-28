package com.openbag.modules.cooperative.dto;

import com.openbag.enums.AddonPricing;
import com.openbag.modules.cooperative.entity.AddonPlan;

import java.math.BigDecimal;

/**
 * Adicional oferecido aos cooperados, com quantos já têm (ativos) e quantos ainda não responderam
 */
public record AddonPlanDTO(Long id, String name, String description, AddonPricing pricing, BigDecimal value,
                           boolean active, long activeMembers, long proposedMembers) {

    public static AddonPlanDTO from(AddonPlan plan, long activeMembers, long proposedMembers) {
        return new AddonPlanDTO(plan.getId(), plan.getName(), plan.getDescription(), plan.getPricing(),
                plan.getValue(), plan.isActive(), activeMembers, proposedMembers);
    }
}
