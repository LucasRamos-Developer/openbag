package com.openbag.modules.cooperative.dto;

import com.openbag.enums.AddonPricing;
import com.openbag.enums.MemberAddonStatus;
import com.openbag.modules.cooperative.entity.MemberAddon;
import com.openbag.modules.organization.entity.AssociationMembership;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/** Adicional de um cooperado (proposto, ativo, recusado ou cancelado) */
public record MemberAddonDTO(Long id, Long planId, String name, String description, AddonPricing pricing,
                             BigDecimal value, MemberAddonStatus status, LocalDateTime proposedAt,
                             LocalDateTime decidedAt, Long membershipId, Integer memberNumber, String memberName) {

    public static MemberAddonDTO from(MemberAddon addon) {
        AssociationMembership membership = addon.getMembership();
        return new MemberAddonDTO(addon.getId(), addon.getPlan().getId(), addon.getPlan().getName(),
                addon.getPlan().getDescription(), addon.getPlan().getPricing(), addon.getPlan().getValue(),
                addon.getStatus(), addon.getProposedAt(), addon.getDecidedAt(), membership.getId(),
                membership.getMemberNumber(), membership.getDeliveryPerson().getUser().getFullName());
    }
}
