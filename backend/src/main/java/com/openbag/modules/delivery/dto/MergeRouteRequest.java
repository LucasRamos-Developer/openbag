package com.openbag.modules.delivery.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;

/**
 * Pedidos que a loja quer mandar juntos numa rota
 */
public record MergeRouteRequest(
        @NotNull(message = "Escolha os pedidos") @Size(min = 2, max = 4, message = "Escolha de 2 a 4 pedidos") List<Long> orderIds) {
}
