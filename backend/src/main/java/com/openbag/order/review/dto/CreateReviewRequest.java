package com.openbag.order.review.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * Avaliação do pedido pelo cliente. A nota do entregador só vale quando o pedido foi levado por um entregador do app.
 */
public record CreateReviewRequest(
        @NotNull @Min(1) @Max(5) Integer restaurantRating,
        @Size(max = 500) String restaurantComment,
        @Min(1) @Max(5) Integer courierRating,
        @Size(max = 500) String courierComment) {
}
