package com.openbag.order.core.service;

import com.openbag.enums.OrderStatus;
import com.openbag.modules.delivery.dispatch.DispatchProperties;
import com.openbag.modules.delivery.entity.DeliveryPerson;
import com.openbag.modules.delivery.tracking.CourierTracking;
import com.openbag.order.core.dto.OrderDTO;
import com.openbag.order.core.entity.Order;
import com.openbag.order.core.repository.OrderRepository;
import com.openbag.order.review.dto.OrderReviewDTO;
import com.openbag.order.review.entity.Review;
import com.openbag.order.review.repository.ReviewRepository;
import com.openbag.order.review.service.ReviewService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.stereotype.Component;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.EnumSet;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Pedido na visão do cliente: {@link OrderDTO#forCustomer} mais a posição do entregador (só quando é a vez do
 * pedido e a localização é recente) e a avaliação.
 */
@Component
public class CustomerOrderMapper {

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private ReviewRepository reviewRepository;

    @Autowired
    private DispatchProperties properties;

    @Autowired
    private Clock clock;

    public OrderDTO toDto(Order order) {
        return toDto(order, reviewRepository.findByOrderId(order.getId()).orElse(null), LocalDateTime.now(clock));
    }

    public Page<OrderDTO> toDtos(Page<Order> orders) {
        Map<Long, Review> reviews = orders.isEmpty() ? Map.of()
                : reviewRepository.findByOrderIds(orders.map(Order::getId).toList()).stream()
                .collect(Collectors.toMap(r -> r.getOrder().getId(), Function.identity()));
        LocalDateTime now = LocalDateTime.now(clock);
        return orders.map(order -> toDto(order, reviews.get(order.getId()), now));
    }

    private OrderDTO toDto(Order order, Review review, LocalDateTime now) {
        OrderDTO dto = OrderDTO.forCustomer(order);
        dto.setCourierLocation(courierLocation(order, now));
        dto.setReview(review == null ? null : OrderReviewDTO.from(review));
        dto.setReviewableUntil(ReviewService.reviewableUntil(order, review != null, now));
        return dto;
    }

    private OrderDTO.Location courierLocation(Order order, LocalDateTime now) {
        DeliveryPerson courier = order.getDeliveryPerson();
        if (order.getStatus() != OrderStatus.OUT_FOR_DELIVERY || courier == null
                || courier.getLastLatitude() == null || courier.getLastLongitude() == null
                || courier.getLastSeenAt() == null
                || courier.getLastSeenAt().isBefore(now.minusSeconds(properties.getLocationStaleSeconds()))) {
            return null;
        }
        var courierOrders = orderRepository.findByCourierAndStatusIn(courier.getId(),
                EnumSet.of(OrderStatus.OUT_FOR_DELIVERY));
        if (!CourierTracking.isTrackable(order, courierOrders)) {
            return null;
        }
        return new OrderDTO.Location(courier.getLastLatitude(), courier.getLastLongitude(), courier.getLastSeenAt());
    }
}
