package com.openbag.modules.review.dto;

import com.openbag.modules.review.entity.Review;

import java.time.LocalDateTime;

/**
 * Avaliação vista pelo cliente que a fez, no detalhe do pedido
 */
public record OrderReviewDTO(Integer restaurantRating, String restaurantComment, Integer courierRating,
                             String courierComment, String restaurantReply, LocalDateTime createdAt) {

    public static OrderReviewDTO from(Review review) {
        return new OrderReviewDTO(review.getRestaurantRating(), review.getRestaurantComment(),
                review.getCourierRating(), review.getCourierComment(), review.getRestaurantReply(),
                review.getCreatedAt());
    }
}
