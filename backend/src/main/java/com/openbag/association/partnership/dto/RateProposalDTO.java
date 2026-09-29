package com.openbag.association.partnership.dto;

import com.openbag.enums.PartnershipSide;
import com.openbag.association.partnership.entity.RestaurantPartnership;
import com.openbag.association.core.dto.DeliveryRateDTO;

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
