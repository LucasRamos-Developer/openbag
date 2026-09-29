package com.openbag.order.review.service;

import com.openbag.enums.OrderStatus;
import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.platform.web.exception.ConflictException;
import com.openbag.platform.web.exception.ResourceNotFoundException;
import com.openbag.delivery.courier.entity.DeliveryPerson;
import com.openbag.delivery.courier.repository.DeliveryPersonRepository;
import com.openbag.order.core.entity.Order;
import com.openbag.order.core.repository.OrderRepository;
import com.openbag.restaurant.store.entity.Restaurant;
import com.openbag.restaurant.store.repository.RestaurantRepository;
import com.openbag.order.review.dto.CreateReviewRequest;
import com.openbag.order.review.dto.OrderReviewDTO;
import com.openbag.order.review.dto.ReviewSummaryDTO;
import com.openbag.order.review.entity.Review;
import com.openbag.order.review.repository.ReviewRepository;
import com.openbag.modules.user.entity.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Clock;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ReviewServiceTest {

    private static final ZoneId ZONE = ZoneId.of("America/Sao_Paulo");
    private static final LocalDateTime NOW = LocalDateTime.of(2026, 9, 27, 20, 0);

    @Mock private ReviewRepository reviewRepository;
    @Mock private OrderRepository orderRepository;
    @Mock private RestaurantRepository restaurantRepository;
    @Mock private DeliveryPersonRepository deliveryPersonRepository;
    @Spy private Clock clock = Clock.fixed(NOW.atZone(ZONE).toInstant(), ZONE);

    @InjectMocks
    private ReviewService service;

    private User customer;
    private Restaurant restaurant;
    private DeliveryPerson courier;
    private Order order;

    @BeforeEach
    void setUp() {
        customer = new User();
        customer.setId(7L);
        restaurant = new Restaurant();
        restaurant.setId(1L);
        courier = new DeliveryPerson();
        courier.setId(5L);
        order = new Order();
        order.setId(100L);
        order.setRestaurant(restaurant);
        order.setUser(customer);
        order.setDeliveryPerson(courier);
        order.setStatus(OrderStatus.DELIVERED);
        order.setDeliveredAt(NOW.minusHours(1));
    }

    private static ReviewRepository.RatingAggregate aggregate(double average, long count) {
        return new ReviewRepository.RatingAggregate() {
            public Double getAverage() { return average; }
            public Long getCount() { return count; }
        };
    }

    private void orderFound() {
        when(orderRepository.findByIdAndUserId(100L, 7L)).thenReturn(Optional.of(order));
    }

    @Test
    void savesBothRatingsAndRefreshesTheAverages() {
        orderFound();
        when(reviewRepository.saveAndFlush(any())).thenAnswer(i -> i.getArgument(0));
        when(reviewRepository.aggregateRestaurant(1L)).thenReturn(aggregate(4.333, 3));
        when(reviewRepository.aggregateCourier(5L)).thenReturn(aggregate(5.0, 1));

        OrderReviewDTO dto = service.create(customer, 100L, new CreateReviewRequest(4, "  Muito bom ", 5, "Rápido"));

        assertThat(dto.restaurantRating()).isEqualTo(4);
        assertThat(dto.restaurantComment()).isEqualTo("Muito bom");
        assertThat(dto.courierRating()).isEqualTo(5);
        assertThat(restaurant.getRating()).isEqualByComparingTo("4.33");
        assertThat(restaurant.getTotalReviews()).isEqualTo(3);
        assertThat(courier.getRating()).isEqualByComparingTo("5.00");
        assertThat(courier.getTotalReviews()).isEqualTo(1);
    }

    @Test
    void courierRatingIsOptional() {
        orderFound();
        when(reviewRepository.saveAndFlush(any())).thenAnswer(i -> i.getArgument(0));
        when(reviewRepository.aggregateRestaurant(1L)).thenReturn(aggregate(3.0, 1));

        service.create(customer, 100L, new CreateReviewRequest(3, null, null, "ignorado"));

        ArgumentCaptor<Review> saved = ArgumentCaptor.forClass(Review.class);
        verify(reviewRepository).saveAndFlush(saved.capture());
        assertThat(saved.getValue().getCourierRating()).isNull();
        assertThat(saved.getValue().getCourierComment()).isNull();
        verify(deliveryPersonRepository, never()).save(any());
    }

    @Test
    void onlyTheCustomerOfTheOrderCanReview() {
        when(orderRepository.findByIdAndUserId(100L, 7L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.create(customer, 100L, new CreateReviewRequest(5, null, null, null)))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void orderMustBeDelivered() {
        order.setStatus(OrderStatus.OUT_FOR_DELIVERY);
        orderFound();

        assertThatThrownBy(() -> service.create(customer, 100L, new CreateReviewRequest(5, null, null, null)))
                .isInstanceOf(BadRequestException.class);
    }

    @Test
    void orderCanBeReviewedOnlyOnce() {
        orderFound();
        when(reviewRepository.existsByOrderId(100L)).thenReturn(true);

        assertThatThrownBy(() -> service.create(customer, 100L, new CreateReviewRequest(5, null, null, null)))
                .isInstanceOf(ConflictException.class);
    }

    @Test
    void reviewWindowIsSevenDays() {
        order.setDeliveredAt(NOW.minusDays(8));
        orderFound();

        assertThatThrownBy(() -> service.create(customer, 100L, new CreateReviewRequest(5, null, null, null)))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("prazo");
        assertThat(ReviewService.reviewableUntil(order, false, NOW)).isNull();
        order.setDeliveredAt(NOW.minusDays(6));
        assertThat(ReviewService.reviewableUntil(order, false, NOW)).isEqualTo(NOW.plusDays(1));
        assertThat(ReviewService.reviewableUntil(order, true, NOW)).isNull();
    }

    @Test
    void storeOwnTeamCannotBeRated() {
        order.setDeliveryPerson(null);
        orderFound();

        assertThatThrownBy(() -> service.create(customer, 100L, new CreateReviewRequest(5, null, 4, null)))
                .isInstanceOf(BadRequestException.class);
    }

    @Test
    void summaryHasTheDistributionByRating() {
        when(reviewRepository.countByRestaurantRating(1L)).thenReturn(List.of(
                new Object[]{5, 3L}, new Object[]{4, 1L}, new Object[]{1, 1L}));

        ReviewSummaryDTO summary = service.summary(1L);

        assertThat(summary.total()).isEqualTo(5);
        assertThat(summary.distribution()).containsExactly(1L, 0L, 0L, 1L, 3L);
        assertThat(summary.average()).isEqualByComparingTo("4.00");
    }
}
