package com.openbag.modules.delivery.dto;

import com.openbag.modules.delivery.entity.RestaurantPartnership;
import com.openbag.modules.organization.dto.DeliveryRateDTO;
import com.openbag.modules.organization.entity.Organization;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Associação parceira do restaurante, com a tabela de valores para comparar com a taxa cobrada
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PartnerDTO {

    private Long organizationId;
    private String name;
    private String logoUrl;
    private String city;
    private String state;
    private DeliveryRateDTO deliveryRate;
    private LocalDateTime since;
    // O valor base da associação passa da taxa de entrega do restaurante
    private boolean exceedsDeliveryFee;

    public static PartnerDTO from(RestaurantPartnership partnership, BigDecimal deliveryFee) {
        Organization organization = partnership.getOrganization();
        var address = organization.getAddress();
        return PartnerDTO.builder()
                .organizationId(organization.getId())
                .name(organization.getTradingName())
                .logoUrl(organization.getLogoUrl())
                .city(address != null ? address.getCity() : null)
                .state(address != null ? address.getState() : null)
                .deliveryRate(DeliveryRateDTO.from(organization.getDeliveryRate()))
                .since(partnership.getCreatedAt())
                .exceedsDeliveryFee(exceedsFee(organization, deliveryFee))
                .build();
    }

    public static boolean exceedsFee(Organization organization, BigDecimal deliveryFee) {
        if (!organization.isDeliveryRateConfigured()) {
            return false;
        }
        BigDecimal fee = deliveryFee != null ? deliveryFee : BigDecimal.ZERO;
        return organization.getDeliveryRate().getBaseFee().compareTo(fee) > 0;
    }
}
