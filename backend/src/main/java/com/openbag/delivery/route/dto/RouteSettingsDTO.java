package com.openbag.delivery.route.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

/**
 * Configurações das rotas da loja
 *
 * @param maxHoldMinutes quanto um pedido pronto pode esperar outro da mesma rota
 * @param leadMinutes    quantos minutos antes de ficar pronto o entregador é chamado
 */
public record RouteSettingsDTO(
        boolean enabled,
        @Min(value = 2, message = "Mínimo de 2 pedidos por rota") @Max(value = 4, message = "Máximo de 4 pedidos por rota") int maxOrders,
        @Min(value = 0, message = "A espera não pode ser negativa") @Max(value = 20, message = "Espera máxima de 20 minutos") int maxHoldMinutes,
        @Min(value = 0, message = "O tempo não pode ser negativo") @Max(value = 30, message = "Máximo de 30 minutos") int leadMinutes) {
}
