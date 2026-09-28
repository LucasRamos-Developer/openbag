package com.openbag.modules.delivery.dto;

import com.openbag.enums.DeliveryFeeMode;
import com.openbag.enums.PartnershipSide;
import com.openbag.enums.PartnershipStatus;
import com.openbag.modules.delivery.entity.RestaurantPartnership;
import com.openbag.modules.organization.dto.DeliveryRateDTO;
import com.openbag.modules.restaurant.entity.Restaurant;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Parceria vista pela associação: a loja, a situação e a tabela que vale nela
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AssociationPartnershipDTO {

    private Long id;
    private Long restaurantId;
    private String restaurantName;
    private String slug;
    private String logoUrl;
    private String neighborhood;
    private String city;
    private String state;
    // Taxa cobrada do cliente e se a loja assume a diferença quando a tabela passa dela
    private BigDecimal deliveryFee;
    // A loja repassa a taxa ao cliente (cobra pela maior tabela): a tabela nunca passa da taxa
    private DeliveryFeeMode deliveryFeeMode;
    private boolean coversDeliveryDifference;
    private PartnershipStatus status;
    private PartnershipSide requestedBy;
    private PartnershipSide endedBy;
    // Quem precisa responder (pedido, contraproposta ou proposta de tabela); nulo = ninguém
    private PartnershipSide awaitingSide;
    private DeliveryRateDTO agreedRate;
    private DeliveryRateDTO effectiveRate;
    private RateProposalDTO rateProposal;
    private LocalDateTime since;
    private LocalDateTime decidedAt;
    private LocalDateTime endedAt;

    public static AssociationPartnershipDTO from(RestaurantPartnership partnership) {
        Restaurant restaurant = partnership.getRestaurant();
        var address = restaurant.getAddress();
        return AssociationPartnershipDTO.builder()
                .id(partnership.getId())
                .restaurantId(restaurant.getId())
                .restaurantName(restaurant.getName())
                .slug(restaurant.getSlug())
                .logoUrl(restaurant.getLogoUrl())
                .neighborhood(address != null ? address.getNeighborhood() : null)
                .city(address != null ? address.getCity() : null)
                .state(address != null ? address.getState() : null)
                .deliveryFee(restaurant.getDeliveryFee())
                .deliveryFeeMode(restaurant.getDeliveryFeeMode())
                .coversDeliveryDifference(restaurant.isCoversDeliveryDifference())
                .status(partnership.getStatus())
                .requestedBy(partnership.getRequestedBy())
                .endedBy(partnership.getEndedBy())
                .awaitingSide(partnership.getAwaitingSide())
                .agreedRate(partnership.hasAgreedRate() ? DeliveryRateDTO.from(partnership.getAgreedRate()) : null)
                .effectiveRate(DeliveryRateDTO.from(partnership.getEffectiveRate()))
                .rateProposal(RateProposalDTO.from(partnership))
                .since(partnership.getCreatedAt())
                .decidedAt(partnership.getDecidedAt())
                .endedAt(partnership.getEndedAt())
                .build();
    }
}
