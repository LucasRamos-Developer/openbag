package com.openbag.order.review.service;

import com.openbag.enums.OrderStatus;
import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.platform.web.exception.ConflictException;
import com.openbag.platform.web.exception.ResourceNotFoundException;
import com.openbag.modules.delivery.entity.DeliveryPerson;
import com.openbag.modules.delivery.repository.DeliveryPersonRepository;
import com.openbag.order.core.entity.Order;
import com.openbag.order.core.repository.OrderRepository;
import com.openbag.restaurant.store.entity.Restaurant;
import com.openbag.restaurant.store.repository.RestaurantRepository;
import com.openbag.order.review.dto.CreateReviewRequest;
import com.openbag.order.review.dto.OrderReviewDTO;
import com.openbag.order.review.dto.ReplyRequest;
import com.openbag.order.review.dto.RestaurantReviewDTO;
import com.openbag.order.review.dto.ReviewSummaryDTO;
import com.openbag.order.review.entity.Review;
import com.openbag.order.review.repository.ReviewRepository;
import com.openbag.modules.user.entity.User;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Clock;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Avaliações dos pedidos: o cliente avalia a loja e o entregador depois da entrega, e a loja pode responder.
 * As médias da loja e do entregador são recalculadas a cada avaliação.
 */
@Service
@Transactional
@Slf4j
public class ReviewService {

    /** Prazo para avaliar, contado da entrega */
    public static final int REVIEW_WINDOW_DAYS = 7;

    @Autowired
    private ReviewRepository reviewRepository;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private RestaurantRepository restaurantRepository;

    @Autowired
    private DeliveryPersonRepository deliveryPersonRepository;

    @Autowired
    private Clock clock;

    /**
     * Até quando o pedido ainda pode ser avaliado; nulo se não pode (não entregue, já avaliado ou fora do prazo)
     */
    public static LocalDateTime reviewableUntil(Order order, boolean reviewed, LocalDateTime now) {
        if (reviewed || order.getStatus() != OrderStatus.DELIVERED || order.getDeliveredAt() == null) {
            return null;
        }
        LocalDateTime until = order.getDeliveredAt().plusDays(REVIEW_WINDOW_DAYS);
        return now.isBefore(until) ? until : null;
    }

    public OrderReviewDTO create(User customer, Long orderId, CreateReviewRequest request) {
        Order order = orderRepository.findByIdAndUserId(orderId, customer.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Pedido não encontrado"));
        if (order.getStatus() != OrderStatus.DELIVERED) {
            throw new BadRequestException("Só dá para avaliar depois que o pedido for entregue");
        }
        if (reviewRepository.existsByOrderId(orderId)) {
            throw new ConflictException("Este pedido já foi avaliado");
        }
        LocalDateTime now = LocalDateTime.now(clock);
        if (reviewableUntil(order, false, now) == null) {
            throw new BadRequestException("O prazo para avaliar este pedido terminou");
        }
        DeliveryPerson courier = order.getDeliveryPerson();
        if (courier == null && request.courierRating() != null) {
            throw new BadRequestException("Este pedido não foi levado por um entregador do app");
        }

        Review review = new Review();
        review.setOrder(order);
        review.setRestaurant(order.getRestaurant());
        review.setUser(customer);
        review.setDeliveryPerson(courier);
        review.setRestaurantRating(request.restaurantRating());
        review.setRestaurantComment(trim(request.restaurantComment()));
        if (courier != null) {
            review.setCourierRating(request.courierRating());
            review.setCourierComment(request.courierRating() != null ? trim(request.courierComment()) : null);
        }
        review.setCreatedAt(now);
        Review saved = reviewRepository.saveAndFlush(review);

        refreshRestaurantRating(order.getRestaurant());
        if (saved.getCourierRating() != null) {
            refreshCourierRating(courier);
        }
        log.info("Pedido {} avaliado: loja {} e entregador {}", orderId, saved.getRestaurantRating(),
                saved.getCourierRating());
        return OrderReviewDTO.from(saved);
    }

    @Transactional(readOnly = true)
    public Page<RestaurantReviewDTO> listForRestaurant(Long restaurantId, Pageable pageable) {
        return reviewRepository.findByRestaurantIdOrderByCreatedAtDesc(restaurantId, pageable)
                .map(RestaurantReviewDTO::from);
    }

    @Transactional(readOnly = true)
    public ReviewSummaryDTO summary(Long restaurantId) {
        List<Long> distribution = new ArrayList<>(Collections.nCopies(5, 0L));
        long total = 0;
        long sum = 0;
        for (Object[] row : reviewRepository.countByRestaurantRating(restaurantId)) {
            int rating = ((Number) row[0]).intValue();
            long count = ((Number) row[1]).longValue();
            if (rating >= 1 && rating <= 5) {
                distribution.set(rating - 1, count);
                total += count;
                sum += rating * count;
            }
        }
        BigDecimal average = total == 0 ? BigDecimal.ZERO
                : BigDecimal.valueOf(sum).divide(BigDecimal.valueOf(total), 2, RoundingMode.HALF_UP);
        return new ReviewSummaryDTO(average, total, distribution);
    }

    public RestaurantReviewDTO reply(Long restaurantId, Long reviewId, ReplyRequest request) {
        Review review = reviewRepository.findByIdAndRestaurantId(reviewId, restaurantId)
                .orElseThrow(() -> new ResourceNotFoundException("Avaliação não encontrada"));
        review.setRestaurantReply(request.reply().trim());
        review.setRepliedAt(LocalDateTime.now(clock));
        return RestaurantReviewDTO.from(reviewRepository.save(review));
    }

    // ============= Médias =============

    private void refreshRestaurantRating(Restaurant restaurant) {
        ReviewRepository.RatingAggregate aggregate = reviewRepository.aggregateRestaurant(restaurant.getId());
        restaurant.setRating(average(aggregate));
        restaurant.setTotalReviews(count(aggregate));
        restaurantRepository.save(restaurant);
    }

    private void refreshCourierRating(DeliveryPerson courier) {
        ReviewRepository.RatingAggregate aggregate = reviewRepository.aggregateCourier(courier.getId());
        courier.setRating(average(aggregate));
        courier.setTotalReviews(count(aggregate));
        deliveryPersonRepository.save(courier);
    }

    private static BigDecimal average(ReviewRepository.RatingAggregate aggregate) {
        return aggregate == null || aggregate.getAverage() == null ? BigDecimal.ZERO
                : BigDecimal.valueOf(aggregate.getAverage()).setScale(2, RoundingMode.HALF_UP);
    }

    private static int count(ReviewRepository.RatingAggregate aggregate) {
        return aggregate == null || aggregate.getCount() == null ? 0 : aggregate.getCount().intValue();
    }

    private static String trim(String text) {
        return text == null || text.isBlank() ? null : text.trim();
    }
}
