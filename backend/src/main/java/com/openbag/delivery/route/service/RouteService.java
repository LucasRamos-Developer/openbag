package com.openbag.delivery.route.service;

import com.openbag.enums.OrderStatus;
import com.openbag.enums.RouteOrigin;
import com.openbag.enums.RouteStatus;
import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.platform.web.exception.ResourceNotFoundException;
import com.openbag.delivery.dispatch.service.DispatchRequestedEvent;
import com.openbag.delivery.dispatch.service.DispatchService;
import com.openbag.delivery.dispatch.service.ReassignPolicy;
import com.openbag.delivery.dispatch.service.RoutePlanner;
import com.openbag.delivery.route.dto.RouteSettingsDTO;
import com.openbag.delivery.route.dto.RoutesBoardDTO;
import com.openbag.delivery.route.entity.DeliveryRoute;
import com.openbag.delivery.route.repository.DeliveryRouteRepository;
import com.openbag.order.core.entity.Order;
import com.openbag.order.realtime.OrderChangedEvent;
import com.openbag.order.core.repository.OrderRepository;
import com.openbag.restaurant.store.entity.Restaurant;
import com.openbag.restaurant.store.repository.RestaurantRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.*;

/**
 * Painel de rotas da loja: acompanhar e corrigir o que o planejador montou (enviar agora, separar, juntar,
 * escolher entregador) e as configurações das rotas
 */
@Service
@Transactional
public class RouteService {

    private static final Set<OrderStatus> ON_BOARD = EnumSet.of(OrderStatus.CONFIRMED, OrderStatus.PREPARING,
            OrderStatus.READY_FOR_PICKUP, OrderStatus.OUT_FOR_DELIVERY);

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private DeliveryRouteRepository routeRepository;

    @Autowired
    private RestaurantRepository restaurantRepository;

    @Autowired
    private DispatchService dispatchService;

    @Autowired
    private ApplicationEventPublisher events;

    @Autowired
    private Clock clock;

    @Transactional(readOnly = true)
    public RoutesBoardDTO board(Long restaurantId) {
        Restaurant restaurant = findRestaurant(restaurantId);
        List<Order> orders = orderRepository.findByRestaurantIdAndStatusInOrderByOrderDateAsc(restaurantId, ON_BOARD);
        List<RoutesBoardDTO.RouteCard> planning = new ArrayList<>();
        List<RoutesBoardDTO.RouteCard> active = new ArrayList<>();
        Set<Long> seenRoutes = new HashSet<>();

        for (Order order : orders) {
            if (order.isPickup()) {
                continue; // retirada na loja: não tem entrega
            }
            boolean withCourier = order.getDeliveryPerson() != null || order.getStaffCourier() != null;
            if (!withCourier && order.getStatus() == OrderStatus.OUT_FOR_DELIVERY) {
                continue; // saiu com a equipe sem marcar quem: fora do painel
            }
            DeliveryRoute route = order.getRoute();
            if (route != null) {
                if (!seenRoutes.add(route.getId())) {
                    continue;
                }
                RoutesBoardDTO.RouteCard card = routeCard(route, restaurant);
                (card.courierName() != null ? active : planning).add(card);
            } else {
                RoutesBoardDTO.RouteCard card = singleCard(order, restaurant);
                (withCourier ? active : planning).add(card);
            }
        }
        return new RoutesBoardDTO(settings(restaurant),
                restaurant.getLatitude() != null ? restaurant.getLatitude().doubleValue() : null,
                restaurant.getLongitude() != null ? restaurant.getLongitude().doubleValue() : null,
                planning, active);
    }

    /** A loja junta pedidos numa rota; ela sai já (procura entregador) e o planejador não a desfaz */
    public void merge(Long restaurantId, List<Long> orderIds) {
        Restaurant restaurant = findRestaurant(restaurantId);
        List<Order> orders = new ArrayList<>();
        // Trava em ordem de id (duas junções com os mesmos pedidos esperam uma pela outra, sem deadlock);
        // a ordem escolhida pela loja continua valendo para a sequência
        orderRepository.findAllByIdForUpdate(new java.util.TreeSet<>(orderIds));
        for (Long id : new java.util.LinkedHashSet<>(orderIds)) {
            Order order = orderRepository.findByIdForUpdate(id)
                    .filter(o -> o.getRestaurant().getId().equals(restaurantId))
                    .orElseThrow(() -> new ResourceNotFoundException("Pedido não encontrado"));
            if (order.isPickup()) {
                throw new BadRequestException("O pedido " + order.getDisplayCode() + " é para retirada na loja");
            }
            if (!DispatchService.DISPATCHABLE.contains(order.getStatus()) || order.getDeliveryPerson() != null
                    || order.getStaffCourier() != null) {
                throw new BadRequestException("O pedido " + order.getDisplayCode() + " já tem entregador ou saiu");
            }
            orders.add(order);
        }
        if (orders.size() < 2) {
            throw new BadRequestException("Escolha pelo menos 2 pedidos");
        }
        for (Order order : orders) {
            dispatchService.pullFromRoute(order);
        }

        LocalDateTime now = LocalDateTime.now(clock);
        List<RoutePlanner.Stop> stops = orders.stream().map(RouteService::toStop).toList();
        List<Long> sequence = hasLocation(restaurant)
                ? RoutePlanner.manualSequence(lat(restaurant), lng(restaurant), stops)
                : orders.stream().map(Order::getId).toList();

        DeliveryRoute route = new DeliveryRoute();
        route.setRestaurant(restaurant);
        route.setOrigin(RouteOrigin.MANUAL);
        route.setStatus(RouteStatus.DISPATCHING);
        route.setCreatedAt(now);
        route.setDispatchedAt(now);
        if (hasLocation(restaurant)) {
            List<RoutePlanner.Stop> ordered = sequence.stream()
                    .map(id -> stops.stream().filter(s -> s.orderId().equals(id)).findFirst().orElseThrow())
                    .toList();
            double[] km = RoutePlanner.distances(lat(restaurant), lng(restaurant), ordered);
            route.setTotalDistanceKm(km[0]);
            route.setSavedDistanceKm(km[1]);
        }
        route = routeRepository.save(route);
        for (Order order : orders) {
            order.setRoute(route);
            route.getOrders().add(order);
            order.setRouteSequence(sequence.indexOf(order.getId()) + 1);
            order.setSoloDispatch(false);
            order.setDispatchReleasedAt(now);
            orderRepository.save(order);
        }
        requestDispatch(route.sortedOrders().get(0), orders);
    }

    /** Chama o entregador agora, sem esperar a hora planejada */
    public void dispatchNow(Long restaurantId, Long routeId) {
        DeliveryRoute route = findRoute(restaurantId, routeId);
        if (route.getStatus() != RouteStatus.PLANNED) {
            throw new BadRequestException("Esta rota já está procurando entregador");
        }
        LocalDateTime now = LocalDateTime.now(clock);
        orderRepository.findAllByIdForUpdate(orderRepository.findIdsByRouteId(routeId));
        List<Order> orders = route.sortedOrders();
        route.setStatus(RouteStatus.DISPATCHING);
        route.setOrigin(RouteOrigin.MANUAL);
        route.setDispatchedAt(now);
        route.setWaitReason(null);
        routeRepository.save(route);
        for (Order order : orders) {
            order.setDispatchReleasedAt(now);
            orderRepository.save(order);
        }
        requestDispatch(orders.get(0), orders);
    }

    /** Pedido sozinho ainda esperando a hora planejada: chama o entregador agora */
    public void dispatchOrderNow(Long restaurantId, Long orderId) {
        Order order = orderRepository.findByIdForUpdate(orderId)
                .filter(o -> o.getRestaurant().getId().equals(restaurantId))
                .orElseThrow(() -> new ResourceNotFoundException("Pedido não encontrado"));
        if (order.getRoute() != null) {
            dispatchNow(restaurantId, order.getRoute().getId());
            return;
        }
        if (order.getDispatchReleasedAt() == null) {
            order.setDispatchReleasedAt(LocalDateTime.now(clock));
            orderRepository.save(order);
        }
        requestDispatch(order, List.of(order));
    }

    /** Tira um pedido de uma rota ainda sem entregador; ele sai sozinho e não volta a ser agrupado */
    public void separate(Long restaurantId, Long routeId, Long orderId) {
        DeliveryRoute route = findRoute(restaurantId, routeId);
        if (route.getDeliveryPerson() != null || route.getStaffCourier() != null) {
            throw new BadRequestException("Esta rota já tem entregador: troque o entregador do pedido na ficha dele");
        }
        Order order = orderRepository.findByIdForUpdate(orderId)
                .filter(o -> route.equals(o.getRoute()))
                .orElseThrow(() -> new ResourceNotFoundException("Pedido não está nesta rota"));
        boolean dispatching = route.getStatus() == RouteStatus.DISPATCHING;
        dispatchService.pullFromRoute(order);
        order.setSoloDispatch(true);
        orderRepository.save(order);

        List<Order> touched = new ArrayList<>(route.sortedOrders());
        touched.add(order);
        if (dispatching && !route.getOrders().isEmpty()) {
            requestDispatch(route.sortedOrders().get(0), touched);
        }
        if (order.getDispatchReleasedAt() != null) {
            events.publishEvent(new DispatchRequestedEvent(order.getId()));
        }
        touched.forEach(o -> events.publishEvent(new OrderChangedEvent(o.getId(), OrderChangedEvent.Type.ORDER_UPDATED)));
    }

    public RouteSettingsDTO updateSettings(Long restaurantId, RouteSettingsDTO request) {
        Restaurant restaurant = findRestaurant(restaurantId);
        restaurant.setRouteBatchingEnabled(request.enabled());
        restaurant.setRouteMaxOrders(request.maxOrders());
        restaurant.setRouteMaxHoldMinutes(request.maxHoldMinutes());
        restaurant.setRouteDispatchLeadMinutes(request.leadMinutes());
        return settings(restaurantRepository.save(restaurant));
    }

    // ============= Auxiliares =============

    private void requestDispatch(Order lead, List<Order> changed) {
        events.publishEvent(new DispatchRequestedEvent(lead.getId()));
        changed.forEach(o -> events.publishEvent(new OrderChangedEvent(o.getId(), OrderChangedEvent.Type.ORDER_UPDATED)));
    }

    private RoutesBoardDTO.RouteCard routeCard(DeliveryRoute route, Restaurant restaurant) {
        List<Order> orders = route.sortedOrders().stream().filter(o -> o.getStatus() != OrderStatus.CANCELLED).toList();
        Order lead = orders.isEmpty() ? null : orders.get(0);
        return new RoutesBoardDTO.RouteCard(route.getId(), route.getStatus(), route.getOrigin(),
                courierName(route), lead != null ? ReassignPolicy.kindOf(lead) : null,
                route.getTotalDistanceKm(), route.getSavedDistanceKm(),
                route.getStatus() == RouteStatus.PLANNED ? route.getDispatchAt() : null,
                route.getStatus() == RouteStatus.PLANNED || route.getStatus() == RouteStatus.DISPATCHING ? route.getWaitReason() : null,
                lead != null ? lead.getSearchingCourierSince() : null,
                orders.stream().map(RouteService::stop).toList());
    }

    private RoutesBoardDTO.RouteCard singleCard(Order order, Restaurant restaurant) {
        boolean released = order.getDispatchReleasedAt() != null || !restaurant.isRouteBatchingEnabled();
        String courier = order.getStaffCourier() != null ? order.getStaffCourier().getName()
                : order.getDeliveryPerson() != null ? order.getDeliveryPerson().getUser().getFullName() : null;
        RouteStatus status = courier != null
                ? (order.getPickedUpAt() != null ? RouteStatus.IN_PROGRESS : RouteStatus.ASSIGNED)
                : (released ? RouteStatus.DISPATCHING : RouteStatus.PLANNED);
        LocalDateTime dispatchAt = null;
        if (status == RouteStatus.PLANNED) {
            LocalDateTime eta = order.getReadyAt() != null ? order.getReadyAt() : order.getExpectedReadyAt();
            dispatchAt = eta != null ? eta.minusMinutes(restaurant.getRouteDispatchLeadMinutes()) : null;
        }
        return new RoutesBoardDTO.RouteCard(null, status, null, courier, ReassignPolicy.kindOf(order), null, null,
                dispatchAt, null, order.getSearchingCourierSince(), List.of(stop(order)));
    }

    private static RoutesBoardDTO.Stop stop(Order order) {
        return new RoutesBoardDTO.Stop(order.getId(), order.getDisplayCode(), order.getStatus(),
                order.getDeliveryNeighborhood(), order.getDeliveryAddress(), order.getDeliveryLatitude(),
                order.getDeliveryLongitude(), order.getReadyAt(), order.getExpectedReadyAt(), order.getPickedUpAt(),
                order.isSoloDispatch());
    }

    private static String courierName(DeliveryRoute route) {
        if (route.getStaffCourier() != null) {
            return route.getStaffCourier().getName();
        }
        return route.getDeliveryPerson() != null ? route.getDeliveryPerson().getUser().getFullName() : null;
    }

    private static RouteSettingsDTO settings(Restaurant restaurant) {
        return new RouteSettingsDTO(restaurant.isRouteBatchingEnabled(), restaurant.getRouteMaxOrders(),
                restaurant.getRouteMaxHoldMinutes(), restaurant.getRouteDispatchLeadMinutes());
    }

    private static RoutePlanner.Stop toStop(Order order) {
        return new RoutePlanner.Stop(order.getId(), order.getDisplayCode(), order.getDeliveryLatitude(),
                order.getDeliveryLongitude(), order.getDeliveryNeighborhood(), order.getReadyAt(),
                order.getExpectedReadyAt(), false);
    }

    private static boolean hasLocation(Restaurant restaurant) {
        return restaurant.getLatitude() != null && restaurant.getLongitude() != null;
    }

    private static double lat(Restaurant restaurant) {
        return restaurant.getLatitude().doubleValue();
    }

    private static double lng(Restaurant restaurant) {
        return restaurant.getLongitude().doubleValue();
    }

    private DeliveryRoute findRoute(Long restaurantId, Long routeId) {
        return routeRepository.findByIdAndRestaurantId(routeId, restaurantId)
                .orElseThrow(() -> new ResourceNotFoundException("Rota não encontrada"));
    }

    private Restaurant findRestaurant(Long restaurantId) {
        return restaurantRepository.findById(restaurantId)
                .orElseThrow(() -> new ResourceNotFoundException("Restaurante não encontrado"));
    }
}
