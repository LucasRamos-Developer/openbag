package com.openbag.order.review.dto;

import com.openbag.order.review.entity.Review;

import java.time.LocalDateTime;

/**
 * Avaliação vista pela loja: só a parte da loja, sem a nota do entregador
 */
public record RestaurantReviewDTO(Long id, String customerName, String orderCode, Integer rating, String comment,
                                  String reply, LocalDateTime repliedAt, LocalDateTime createdAt) {

    public static RestaurantReviewDTO from(Review review) {
        return new RestaurantReviewDTO(review.getId(), firstName(review.getUser().getFullName()),
                review.getOrder().getDisplayCode(), review.getRestaurantRating(), review.getRestaurantComment(),
                review.getRestaurantReply(), review.getRepliedAt(), review.getCreatedAt());
    }

    // Só o primeiro nome do cliente
    private static String firstName(String fullName) {
        if (fullName == null || fullName.isBlank()) {
            return "Cliente";
        }
        return fullName.trim().split("\\s+")[0];
    }
}
