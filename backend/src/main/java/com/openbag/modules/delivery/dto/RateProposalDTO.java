package com.openbag.modules.delivery.dto;

import com.openbag.enums.PartnershipSide;
import com.openbag.modules.delivery.entity.RestaurantPartnership;
import com.openbag.modules.organization.dto.DeliveryRateDTO;

import java.time.LocalDateTime;

/**
 * Proposta de tabela especial aguardando o outro lado. {@code toDefault} = voltar à tabela da associação.
 */
public record RateProposalDTO(DeliveryRateDTO rate, boolean toDefault, PartnershipSide proposedBy,
                              LocalDateTime proposedAt) {

    public static RateProposalDTO from(RestaurantPartnership partnership) {
        if (!partnership.hasRateProposal()) {
            return null;
        }
        return new RateProposalDTO(
                partnership.isRateProposalToDefault() ? null : DeliveryRateDTO.from(partnership.getProposedRate()),
                partnership.isRateProposalToDefault(), partnership.getRateProposedBy(), partnership.getRateProposedAt());
    }
}
