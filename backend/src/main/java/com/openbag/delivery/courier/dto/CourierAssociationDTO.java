package com.openbag.delivery.courier.dto;

import com.openbag.enums.MembershipStatus;
import com.openbag.modules.organization.entity.AssociationMembership;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Associação do entregador como aparece no perfil e na placa de verificação
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CourierAssociationDTO {

    private Long organizationId;
    private String name;
    private String logoUrl;
    private Integer memberNumber;
    private MembershipStatus status;
    // Vínculo ACTIVE com uma associação aprovada: o selo "verificado" do perfil público
    private boolean verified;

    public static CourierAssociationDTO from(AssociationMembership membership) {
        return CourierAssociationDTO.builder()
                .organizationId(membership.getOrganization().getId())
                .name(membership.getOrganization().getTradingName())
                .logoUrl(membership.getOrganization().getLogoUrl())
                .memberNumber(membership.getMemberNumber())
                .status(membership.getStatus())
                .verified(membership.getStatus() == MembershipStatus.ACTIVE
                        && membership.getOrganization().isOperational())
                .build();
    }
}
