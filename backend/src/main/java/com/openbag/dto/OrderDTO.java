package com.openbag.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class OrderDTO {
    private Long id;
    private Long restaurantId;
    private String restaurantName;
    private Long addressId;
    private String paymentMethod;
    private String status;
    private BigDecimal totalAmount;
    private BigDecimal deliveryFee;
    private String notes;
    private LocalDateTime orderDate;
    private LocalDateTime estimatedDeliveryTime;
    private List<OrderItemDTO> items;

    // Nested class for OrderItemDTO
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class OrderItemDTO {
        private Long productId;
        private String productName;
        private Integer quantity;
        private BigDecimal unitPrice;
        private BigDecimal subtotal;
        private String notes;
    }
}
