package com.openbag.association.finance.dto;

import com.openbag.association.finance.entity.AddonPricing;
import com.openbag.association.finance.entity.MemberAddonStatus;
import com.openbag.association.finance.entity.MemberAddon;
import com.openbag.association.core.entity.AssociationMembership;

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
