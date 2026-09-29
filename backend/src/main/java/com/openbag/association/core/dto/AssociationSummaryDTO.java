package com.openbag.association.core.dto;

import com.openbag.enums.OrganizationType;
import com.openbag.association.core.entity.Organization;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Dados públicos de uma associação (listagem para entregadores e validação de convite)
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class AssociationSummaryDTO {

    private Long id;
    private OrganizationType type;
    private String tradingName;
    private String description;
    private String logoUrl;
    private String city;
    private String state;
    private DeliveryRateDTO deliveryRate;

    public static AssociationSummaryDTO from(Organization organization) {
        var address = organization.getAddress();
        return new AssociationSummaryDTO(
                organization.getId(),
                organization.getType(),
                organization.getTradingName(),
                organization.getDescription(),
                organization.getLogoUrl(),
                address != null ? address.getCity() : null,
                address != null ? address.getState() : null,
                DeliveryRateDTO.from(organization.getDeliveryRate())
        );
    }
}
