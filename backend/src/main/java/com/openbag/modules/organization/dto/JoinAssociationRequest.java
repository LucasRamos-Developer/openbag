package com.openbag.modules.organization.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Pedido de entrada em uma associação. Informe inviteCode ou organizationId")
public class JoinAssociationRequest {

    private Long organizationId;

    private String inviteCode;
}
