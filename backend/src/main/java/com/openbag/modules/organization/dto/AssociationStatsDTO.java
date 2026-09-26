package com.openbag.modules.organization.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AssociationStatsDTO {

    private long activeMembers;
    private long pendingRequests;
    private long suspendedMembers;
    private long availableNow;
    private long totalDeliveries;
    private long activeInvites;

    // Quantidade de vínculos por status (inclui histórico: recusados, desligados...)
    private Map<String, Long> membersByStatus;

    // Associados ativos por tipo de veículo
    private Map<String, Long> activeMembersByVehicleType;
}
