package com.openbag.modules.restaurant.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RestaurantOnboardingResponse {
    private Long restaurantId;
    private String message;
    private String slug;

    public RestaurantOnboardingResponse(Long restaurantId, String message) {
        this.restaurantId = restaurantId;
        this.message = message;
    }
}
