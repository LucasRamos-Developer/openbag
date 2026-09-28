package com.openbag.modules.delivery.dto;

import com.openbag.modules.organization.dto.DeliveryRateDTO;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;

/**
 * A associação convida uma loja para ser parceira, opcionalmente já propondo uma tabela especial
 * (sem {@code rate}, vale a tabela padrão da associação)
 */
public record InviteRestaurantRequest(@NotNull(message = "Informe a loja") Long restaurantId,
                                      @Valid DeliveryRateDTO rate) {
}
