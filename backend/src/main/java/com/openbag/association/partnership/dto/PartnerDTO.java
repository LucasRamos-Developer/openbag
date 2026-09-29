package com.openbag.association.partnership.dto;

import com.openbag.enums.PartnershipSide;
import com.openbag.enums.PartnershipStatus;
import com.openbag.association.partnership.entity.RestaurantPartnership;
import com.openbag.association.core.dto.DeliveryRateDTO;
import com.openbag.association.core.entity.DeliveryRate;
import com.openbag.association.core.entity.Organization;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Parceria vista pelo restaurante: a associação, a situação e a tabela que vale na loja
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PartnerDTO {

    private Long id;
    private Long organizationId;
    private String name;
    private String logoUrl;
    private String city;
    private String state;
    private PartnershipStatus status;
    private PartnershipSide requestedBy;
    private PartnershipSide endedBy;
    // Quem precisa responder (pedido, contraproposta ou proposta de tabela); nulo = ninguém
    private PartnershipSide awaitingSide;
    // Tabela padrão da associação
    private DeliveryRateDTO deliveryRate;
    // Tabela especial combinada com esta loja (nula = vale a padrão)
    private DeliveryRateDTO agreedRate;
    private DeliveryRateDTO effectiveRate;
    private RateProposalDTO rateProposal;
    private LocalDateTime since;
    private LocalDateTime decidedAt;
    private LocalDateTime endedAt;
    // O valor base que vale na loja passa da taxa de entrega do restaurante
    private boolean exceedsDeliveryFee;

    public static PartnerDTO from(RestaurantPartnership partnership, BigDecimal deliveryFee) {
        Organization organization = partnership.getOrganization();
        var address = organization.getAddress();
        return PartnerDTO.builder()
                .id(partnership.getId())
                .organizationId(organization.getId())
                .name(organization.getTradingName())
                .logoUrl(organization.getLogoUrl())
                .city(address != null ? address.getCity() : null)
                .state(address != null ? address.getState() : null)
                .status(partnership.getStatus())
                .requestedBy(partnership.getRequestedBy())
                .endedBy(partnership.getEndedBy())
                .awaitingSide(partnership.getAwaitingSide())
                .deliveryRate(DeliveryRateDTO.from(organization.getDeliveryRate()))
                .agreedRate(partnership.hasAgreedRate() ? DeliveryRateDTO.from(partnership.getAgreedRate()) : null)
                .effectiveRate(DeliveryRateDTO.from(partnership.getEffectiveRate()))
                .rateProposal(RateProposalDTO.from(partnership))
                .since(partnership.getCreatedAt())
                .decidedAt(partnership.getDecidedAt())
                .endedAt(partnership.getEndedAt())
                // Quem repassa a taxa cobra do cliente pela tabela: nunca fica abaixo dela
                .exceedsDeliveryFee(!partnership.getRestaurant().passesDeliveryFee()
                        && exceedsFee(partnership.getEffectiveRate(), deliveryFee))
                .build();
    }

    public static boolean exceedsFee(DeliveryRate rate, BigDecimal deliveryFee) {
        if (rate == null || !rate.isConfigured()) {
            return false;
        }
        BigDecimal fee = deliveryFee != null ? deliveryFee : BigDecimal.ZERO;
        return rate.getBaseFee().compareTo(fee) > 0;
    }
}
