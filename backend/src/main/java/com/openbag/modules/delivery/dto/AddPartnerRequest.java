package com.openbag.modules.delivery.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class AddPartnerRequest {

    @NotNull(message = "Escolha a associação")
    private Long organizationId;
}
