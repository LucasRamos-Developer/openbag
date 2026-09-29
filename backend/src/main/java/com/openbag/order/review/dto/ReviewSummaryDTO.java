package com.openbag.order.review.dto;

import java.math.BigDecimal;
import java.util.List;

/**
 * Resumo das avaliações da loja. {@code distribution} tem 5 posições: quantidade de notas 1, 2, 3, 4 e 5.
 */
public record ReviewSummaryDTO(BigDecimal average, long total, List<Long> distribution) {
}
