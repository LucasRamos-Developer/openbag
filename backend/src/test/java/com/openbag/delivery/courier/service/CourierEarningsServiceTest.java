package com.openbag.delivery.courier.service;

import com.openbag.order.core.entity.OrderStatus;
import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.delivery.courier.dto.CourierEarningsDTO;
import com.openbag.delivery.courier.entity.DeliveryPerson;
import com.openbag.delivery.courier.repository.DeliveryPersonRepository;
import com.openbag.order.core.entity.Order;
import com.openbag.order.core.repository.OrderRepository;
import com.openbag.restaurant.store.entity.Restaurant;
import com.openbag.account.entity.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.*;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CourierEarningsServiceTest {

    private static final ZoneId ZONE = ZoneId.of("America/Sao_Paulo");
    // Quinta-feira, 24/09/2026
    private static final LocalDate TODAY = LocalDate.of(2026, 9, 24);

    @Spy
    private Clock clock = Clock.fixed(TODAY.atTime(15, 0).atZone(ZONE).toInstant(), ZONE);

    @Mock
    private DeliveryPersonRepository deliveryPersonRepository;

    @Mock
    private OrderRepository orderRepository;

    @InjectMocks
    private CourierEarningsService service;

    private User user;

    @BeforeEach
    void setUp() {
        user = new User();
        user.setId(1L);
        DeliveryPerson courier = new DeliveryPerson();
        courier.setId(5L);
        when(deliveryPersonRepository.findByUserId(1L)).thenReturn(Optional.of(courier));
        lenient().when(orderRepository.findDeliveredByCourierBetween(eq(5L), any(), any())).thenReturn(List.of());
    }

    private static Order delivered(LocalDateTime at, String fee) {
        Restaurant restaurant = new Restaurant();
        restaurant.setName("Lanche");
        Order order = new Order();
        order.setRestaurant(restaurant);
        order.setStatus(OrderStatus.DELIVERED);
        order.setDeliveredAt(at);
        order.setCourierFee(new BigDecimal(fee));
        return order;
    }

    @Test
    void dailySeriesCoversEveryDayOfThePeriodIncludingEmptyOnes() {
        List<Order> period = List.of(
                delivered(TODAY.atTime(12, 0), "10.00"),
                delivered(TODAY.atTime(11, 0), "7.50"),
                delivered(TODAY.minusDays(2).atTime(20, 0), "8.00"));
        when(orderRepository.findDeliveredByCourierBetween(5L, TODAY.minusDays(6).atStartOfDay(),
                TODAY.plusDays(1).atStartOfDay())).thenReturn(period);

        CourierEarningsDTO dto = service.getEarnings(user, null, null);

        assertThat(dto.getDaily()).hasSize(7);
        assertThat(dto.getDaily().get(6).date()).isEqualTo(TODAY);
        assertThat(dto.getDaily().get(6).amount()).isEqualByComparingTo("17.50");
        assertThat(dto.getDaily().get(6).deliveries()).isEqualTo(2);
        assertThat(dto.getDaily().get(5).amount()).isEqualByComparingTo("0");
        assertThat(dto.getDaily().get(4).amount()).isEqualByComparingTo("8.00");
        assertThat(dto.getPeriod().amount()).isEqualByComparingTo("25.50");
        assertThat(dto.getDeliveries()).hasSize(3);
    }

    @Test
    void weekStartsOnMonday() {
        service.getEarnings(user, null, null);
        // Semana: segunda 21/09 até hoje
        org.mockito.Mockito.verify(orderRepository).findDeliveredByCourierBetween(5L,
                LocalDate.of(2026, 9, 21).atStartOfDay(), TODAY.plusDays(1).atStartOfDay());
    }

    @Test
    void rejectsInvertedOrTooLongPeriods() {
        assertThatThrownBy(() -> service.getEarnings(user, TODAY, TODAY.minusDays(1))).isInstanceOf(BadRequestException.class);
        assertThatThrownBy(() -> service.getEarnings(user, TODAY.minusDays(200), TODAY)).isInstanceOf(BadRequestException.class);
    }
}
