package com.openbag.modules.delivery.dispatch;

import net.javacrumbs.shedlock.spring.annotation.SchedulerLock;
import com.openbag.enums.RouteOrigin;
import com.openbag.enums.RouteStatus;
import com.openbag.modules.delivery.dispatch.RoutePlanner.Group;
import com.openbag.modules.delivery.entity.DeliveryRoute;
import com.openbag.modules.delivery.repository.DeliveryRouteRepository;
import com.openbag.order.core.entity.Order;
import com.openbag.order.core.repository.OrderRepository;
import com.openbag.order.realtime.OrderChangedEvent;
import com.openbag.restaurant.store.entity.Restaurant;
import com.openbag.restaurant.store.repository.RestaurantRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Planejador de rotas: de tempos em tempos, junta os pedidos que esperam entregador em rotas (mesmo bairro ou
 * direção) e libera a chamada do entregador perto de ficarem prontos. Rotas montadas pela loja não são mexidas.
 */
@Service
@Slf4j
public class RoutePlanningService {

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private RestaurantRepository restaurantRepository;

    @Autowired
    private DeliveryRouteRepository routeRepository;

    @Autowired
    private ApplicationEventPublisher events;

    @Autowired
    private Clock clock;

    private final TransactionTemplate transaction;

    public RoutePlanningService(PlatformTransactionManager transactionManager) {
        this.transaction = new TransactionTemplate(transactionManager);
    }

    @Scheduled(fixedDelayString = "${app.delivery.route-planning-ms:10000}",
            initialDelayString = "${app.delivery.route-planning-initial-delay-ms:20000}")
    @SchedulerLock(name = "dispatch.planRoutes", lockAtMostFor = "PT5M", lockAtLeastFor = "PT3S")
    public void planRoutes() {
        for (Long restaurantId : orderRepository.findRestaurantIdsAwaitingRelease(DispatchService.DISPATCHABLE)) {
            DispatchService.withRetry("rotas do restaurante " + restaurantId,
                    () -> transaction.executeWithoutResult(tx -> planRestaurant(restaurantId)));
        }
    }

    /**
     * Refaz as rotas automáticas ainda montando e libera as que chegaram na hora de chamar o entregador
     */
    void planRestaurant(Long restaurantId) {
        Restaurant restaurant = restaurantRepository.findById(restaurantId).orElseThrow();
        LocalDateTime now = LocalDateTime.now(clock);
        List<Order> waiting = orderRepository.findAwaitingReleaseForUpdate(restaurantId, DispatchService.DISPATCHABLE);
        if (waiting.isEmpty()) {
            return;
        }

        // Rotas desligadas ou loja sem localização: cada pedido chama entregador na hora, como antes
        if (!restaurant.isRouteBatchingEnabled() || restaurant.getLatitude() == null || restaurant.getLongitude() == null) {
            for (Order order : waiting) {
                release(order, now);
            }
            return;
        }

        Map<Long, Order> byId = waiting.stream().collect(Collectors.toMap(Order::getId, Function.identity()));
        List<RoutePlanner.Stop> stops = waiting.stream().map(RoutePlanningService::toStop).toList();
        List<Group> groups = RoutePlanner.plan(restaurant.getLatitude().doubleValue(), restaurant.getLongitude().doubleValue(),
                stops, new RoutePlanner.Settings(restaurant.getRouteMaxOrders(), restaurant.getRouteMaxHoldMinutes(),
                        restaurant.getRouteDispatchLeadMinutes()), now);

        // Rotas automáticas atuais: reaproveita a que tem exatamente os mesmos pedidos
        Map<Set<Long>, DeliveryRoute> current = new HashMap<>();
        for (DeliveryRoute route : routeRepository.findByRestaurantAndStatusIn(restaurantId, EnumSet.of(RouteStatus.PLANNED))) {
            if (route.getOrigin() == RouteOrigin.AUTO) {
                current.put(route.getOrders().stream().map(Order::getId).collect(Collectors.toSet()), route);
            }
        }

        boolean changed = false;
        for (Group group : groups) {
            List<Order> orders = group.orderIds().stream().map(byId::get).toList();
            DeliveryRoute route = null;
            if (orders.size() > 1) {
                route = current.remove(new HashSet<>(group.orderIds()));
                if (route == null) {
                    route = new DeliveryRoute();
                    route.setRestaurant(restaurant);
                    route.setCreatedAt(now);
                    changed = true;
                }
                route.setTotalDistanceKm(group.totalKm());
                route.setSavedDistanceKm(group.savedKm());
                route.setDispatchAt(group.dispatchAt());
                route.setWaitReason(group.waitReason());
                route = routeRepository.save(route);
            }
            for (int i = 0; i < orders.size(); i++) {
                Order order = orders.get(i);
                if (order.getRoute() != route) {
                    if (order.getRoute() != null) {
                        order.getRoute().getOrders().remove(order);
                    }
                    order.setRoute(route);
                    if (route != null) {
                        route.getOrders().add(order);
                    }
                    changed = true;
                }
                order.setRouteSequence(route != null ? i + 1 : null);
            }
            if (group.dueAt(now)) {
                if (route != null) {
                    route.setStatus(RouteStatus.DISPATCHING);
                    route.setDispatchedAt(now);
                    routeRepository.save(route);
                    log.info("Rota {} liberada: {} pedidos, {} km, economia de {} km", route.getId(), orders.size(),
                            group.totalKm(), group.savedKm());
                }
                orders.forEach(o -> release(o, now));
                changed = true;
            } else {
                orderRepository.saveAll(orders);
            }
        }

        // Rotas antigas que não existem mais
        for (DeliveryRoute stale : current.values()) {
            for (Order order : new ArrayList<>(stale.getOrders())) {
                if (order.getRoute() == stale) {
                    order.setRoute(null);
                    order.setRouteSequence(null);
                    orderRepository.save(order);
                }
            }
            stale.getOrders().clear();
            stale.setStatus(RouteStatus.CANCELLED);
            routeRepository.save(stale);
            changed = true;
        }
        if (changed) {
            // O quadro de pedidos e o painel de rotas se atualizam pelo tópico da loja
            waiting.forEach(o -> events.publishEvent(new OrderChangedEvent(o.getId(), OrderChangedEvent.Type.ORDER_UPDATED)));
        }
    }

    private void release(Order order, LocalDateTime now) {
        order.setDispatchReleasedAt(now);
        orderRepository.save(order);
        events.publishEvent(new DispatchRequestedEvent(order.getId()));
    }

    static RoutePlanner.Stop toStop(Order order) {
        return new RoutePlanner.Stop(order.getId(), order.getDisplayCode(), order.getDeliveryLatitude(),
                order.getDeliveryLongitude(), order.getDeliveryNeighborhood(), order.getReadyAt(),
                order.getExpectedReadyAt(), order.isSoloDispatch());
    }
}
