package com.openbag.modules.order.service;

import com.openbag.enums.CancelledBy;
import com.openbag.enums.FulfillmentType;
import com.openbag.enums.OrderStatus;
import com.openbag.exception.BadRequestException;
import com.openbag.exception.ResourceNotFoundException;
import com.openbag.modules.order.entity.Order;
import com.openbag.modules.order.realtime.OrderChangedEvent;
import com.openbag.modules.order.repository.OrderRepository;
import com.openbag.modules.restaurant.entity.Restaurant;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class RestaurantOrderServiceTest {

    private static final long RID = 1L;

    @Mock private OrderRepository orderRepository;
    @Spy private OrderService orderService = new OrderService();
    @Mock private ApplicationEventPublisher events;
    @Spy private Clock clock = Clock.fixed(Instant.parse("2026-09-25T15:00:00Z"), ZoneId.of("America/Sao_Paulo"));

    @InjectMocks
    private RestaurantOrderService service;

    private Order order;

    @BeforeEach
    void setUp() {
        Restaurant restaurant = new Restaurant();
        restaurant.setId(RID);
        restaurant.setName("Burger");
        order = new Order();
        order.setId(10L);
        order.setRestaurant(restaurant);
        order.setStatus(OrderStatus.PENDING);
        order.setSubtotal(BigDecimal.TEN);
        order.setDeliveryFee(BigDecimal.ONE);
        order.setTotalAmount(BigDecimal.valueOf(11));
        lenient().when(orderRepository.findByIdAndRestaurantId(10L, RID)).thenReturn(Optional.of(order));
        lenient().when(orderRepository.save(any(Order.class))).thenAnswer(inv -> inv.getArgument(0));
    }

    @Test
    void acceptingPendingConfirmsRecordsTimeAndNotifies() {
        var dto = service.accept(RID, 10L);

        assertThat(dto.getStatus()).isEqualTo(OrderStatus.CONFIRMED);
        assertThat(order.getAcceptedAt()).isEqualTo(LocalDateTime.now(clock));
        assertThat(dto.getTimeline()).extracting(t -> t.getStatus()).containsExactly(OrderStatus.CONFIRMED);
        verify(events).publishEvent(new OrderChangedEvent(10L, OrderChangedEvent.Type.ORDER_UPDATED));
    }

    @Test
    void stepsMustFollowTheFlow() {
        assertThatThrownBy(() -> service.start(RID, 10L)).isInstanceOf(BadRequestException.class);
        assertThatThrownBy(() -> service.dispatch(RID, 10L)).isInstanceOf(BadRequestException.class);
        verify(events, never()).publishEvent(any());
    }

    @Test
    void kitchenCanMarkReadyStraightFromConfirmed() {
        order.setStatus(OrderStatus.CONFIRMED);
        assertThat(service.ready(RID, 10L).getStatus()).isEqualTo(OrderStatus.READY_FOR_PICKUP);
        assertThat(order.getReadyAt()).isNotNull();
    }

    @Test
    void deliveringMarksPaymentAsReceived() {
        order.setStatus(OrderStatus.OUT_FOR_DELIVERY);
        service.deliver(RID, 10L);
        assertThat(order.getStatus()).isEqualTo(OrderStatus.DELIVERED);
        assertThat(order.getPaymentStatus()).isEqualTo(Order.PaymentStatus.PAID);
        assertThat(order.getDeliveredAt()).isNotNull();
    }

    @Test
    void rejectingRequiresReasonAndIsOnlyAllowedBeforeReady() {
        assertThatThrownBy(() -> service.reject(RID, 10L, " ")).isInstanceOf(BadRequestException.class);

        service.reject(RID, 10L, "Acabou o pão");
        assertThat(order.getStatus()).isEqualTo(OrderStatus.CANCELLED);
        assertThat(order.getCancelledBy()).isEqualTo(CancelledBy.RESTAURANT);
        assertThat(order.getCancellationReason()).isEqualTo("Acabou o pão");

        order.setStatus(OrderStatus.READY_FOR_PICKUP);
        assertThatThrownBy(() -> service.reject(RID, 10L, "Tarde demais")).isInstanceOf(BadRequestException.class);
    }

    @Test
    void pickupGoesFromReadyStraightToDeliveredAndNeverOutForDelivery() {
        order.setFulfillment(FulfillmentType.PICKUP);
        order.setStatus(OrderStatus.READY_FOR_PICKUP);

        assertThatThrownBy(() -> service.dispatch(RID, 10L)).isInstanceOf(BadRequestException.class);

        var dto = service.deliver(RID, 10L);
        assertThat(dto.getStatus()).isEqualTo(OrderStatus.DELIVERED);
        assertThat(order.getPaymentStatus()).isEqualTo(Order.PaymentStatus.PAID);
        assertThat(dto.getTimeline()).extracting(t -> t.getMessage()).containsExactly("Pedido retirado pelo cliente");
    }

    @Test
    void deliveryOnlyFinishesAfterLeaving() {
        order.setStatus(OrderStatus.READY_FOR_PICKUP);
        assertThatThrownBy(() -> service.deliver(RID, 10L)).isInstanceOf(BadRequestException.class);
    }

    @Test
    void orderFromAnotherRestaurantIsNotFound() {
        when(orderRepository.findByIdAndRestaurantId(10L, 2L)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.accept(2L, 10L)).isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void unansweredOrdersExpireAsSystemCancellation() {
        when(orderRepository.findByStatusAndAcceptDeadlineBefore(OrderStatus.PENDING, LocalDateTime.now(clock)))
                .thenReturn(List.of(order));

        service.expireUnansweredOrders();

        assertThat(order.getStatus()).isEqualTo(OrderStatus.CANCELLED);
        assertThat(order.getCancelledBy()).isEqualTo(CancelledBy.SYSTEM);
        verify(events).publishEvent(new OrderChangedEvent(10L, OrderChangedEvent.Type.ORDER_UPDATED));
    }
}
