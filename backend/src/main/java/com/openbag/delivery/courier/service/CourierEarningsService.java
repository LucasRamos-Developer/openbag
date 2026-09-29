package com.openbag.delivery.courier.service;

import com.openbag.enums.CourierLinkStatus;
import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.platform.web.exception.ResourceNotFoundException;
import com.openbag.delivery.courier.dto.CourierEarningsDTO;
import com.openbag.delivery.courier.dto.WorkHistoryDTO;
import com.openbag.delivery.courier.entity.DeliveryPerson;
import com.openbag.delivery.courier.repository.CourierShiftRepository;
import com.openbag.delivery.courier.repository.DeliveryPersonRepository;
import com.openbag.delivery.link.repository.RestaurantCourierLinkRepository;
import com.openbag.order.core.entity.Order;
import com.openbag.order.core.repository.OrderRepository;
import com.openbag.restaurant.store.entity.Restaurant;
import com.openbag.restaurant.store.repository.RestaurantRepository;
import com.openbag.modules.user.entity.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.time.temporal.TemporalAdjusters;
import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Ganhos e histórico de trabalho do entregador. O ganho de cada entrega é o {@code courierFee} fixado no aceite.
 */
@Service
@Transactional(readOnly = true)
public class CourierEarningsService {

    private static final int MAX_PERIOD_DAYS = 92;

    @Autowired
    private DeliveryPersonRepository deliveryPersonRepository;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private CourierShiftRepository shiftRepository;

    @Autowired
    private RestaurantRepository restaurantRepository;

    @Autowired
    private RestaurantCourierLinkRepository linkRepository;

    @Autowired
    private Clock clock;

    /**
     * Resumo de hoje, da semana (desde segunda) e do mês, mais a série diária e as entregas de [from, to]
     * (padrão: últimos 7 dias)
     */
    public CourierEarningsDTO getEarnings(User user, LocalDate from, LocalDate to) {
        DeliveryPerson courier = findCourier(user);
        LocalDate today = LocalDate.now(clock);
        LocalDate end = to != null ? to : today;
        LocalDate start = from != null ? from : end.minusDays(6);
        if (start.isAfter(end)) {
            throw new BadRequestException("A data inicial deve ser anterior à final");
        }
        if (ChronoUnit.DAYS.between(start, end) >= MAX_PERIOD_DAYS) {
            throw new BadRequestException("Escolha um período de até " + MAX_PERIOD_DAYS + " dias");
        }

        List<Order> period = delivered(courier, start, end);
        Map<LocalDate, List<Order>> byDay = period.stream()
                .collect(Collectors.groupingBy(o -> o.getDeliveredAt().toLocalDate()));
        List<CourierEarningsDTO.Day> daily = new ArrayList<>();
        for (LocalDate day = start; !day.isAfter(end); day = day.plusDays(1)) {
            List<Order> orders = byDay.getOrDefault(day, List.of());
            daily.add(new CourierEarningsDTO.Day(day, sum(orders), orders.size()));
        }

        return CourierEarningsDTO.builder()
                .today(total(delivered(courier, today, today)))
                .week(total(delivered(courier, today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY)), today)))
                .month(total(delivered(courier, today.withDayOfMonth(1), today)))
                .from(start)
                .to(end)
                .period(total(period))
                .daily(daily)
                .deliveries(period.stream()
                        .map(o -> new CourierEarningsDTO.Delivery(o.getId(), o.getDisplayCode(), o.getDeliveredAt(),
                                o.getRestaurant().getName(), o.getDeliveryDistanceKm(), fee(o)))
                        .toList())
                .build();
    }

    public WorkHistoryDTO getHistory(User user) {
        DeliveryPerson courier = findCourier(user);
        return WorkHistoryDTO.builder()
                .restaurants(restaurantsWorked(courier))
                .recentShifts(shiftRepository.findRecentByCourier(courier.getId(), PageRequest.of(0, 20)).stream()
                        .map(s -> new WorkHistoryDTO.ShiftEntry(s.getId(), s.getMode(),
                                s.getRestaurant() != null ? s.getRestaurant().getName() : null,
                                s.getStartedAt(), s.getEndedAt(), s.getDeliveriesCount()))
                        .toList())
                .build();
    }

    /**
     * Restaurantes em que o entregador fez entregas (também exibido no perfil público, se ele permitir)
     */
    public List<WorkHistoryDTO.RestaurantEntry> restaurantsWorked(DeliveryPerson courier) {
        List<Object[]> rows = orderRepository.summarizeRestaurantsByCourier(courier.getId());
        Map<Long, Restaurant> restaurants = restaurantRepository
                .findAllById(rows.stream().map(r -> (Long) r[0]).toList()).stream()
                .collect(Collectors.toMap(Restaurant::getId, Function.identity()));
        Set<Long> fixedAt = linkRepository.findByCourier(courier.getId(), EnumSet.of(CourierLinkStatus.ACTIVE)).stream()
                .map(l -> l.getRestaurant().getId())
                .collect(Collectors.toSet());

        List<WorkHistoryDTO.RestaurantEntry> result = new ArrayList<>();
        for (Object[] row : rows) {
            Restaurant restaurant = restaurants.get((Long) row[0]);
            if (restaurant == null) {
                continue;
            }
            result.add(new WorkHistoryDTO.RestaurantEntry(restaurant.getId(), restaurant.getName(), restaurant.getSlug(),
                    restaurant.getLogoUrl(), (Long) row[1], (LocalDateTime) row[2], (LocalDateTime) row[3],
                    fixedAt.contains(restaurant.getId())));
        }
        return result;
    }

    private List<Order> delivered(DeliveryPerson courier, LocalDate from, LocalDate to) {
        return orderRepository.findDeliveredByCourierBetween(courier.getId(), from.atStartOfDay(),
                to.plusDays(1).atStartOfDay());
    }

    private static CourierEarningsDTO.Total total(List<Order> orders) {
        return new CourierEarningsDTO.Total(sum(orders), orders.size());
    }

    private static BigDecimal sum(List<Order> orders) {
        return orders.stream().map(CourierEarningsService::fee).reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private static BigDecimal fee(Order order) {
        return order.getCourierFee() != null ? order.getCourierFee() : BigDecimal.ZERO;
    }

    private DeliveryPerson findCourier(User user) {
        return deliveryPersonRepository.findByUserId(user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Perfil de entregador não encontrado"));
    }
}
