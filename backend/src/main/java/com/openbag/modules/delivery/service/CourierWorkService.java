package com.openbag.modules.delivery.service;

import com.openbag.enums.CourierLinkStatus;
import com.openbag.enums.CourierWorkStatus;
import com.openbag.enums.DeliveryOfferStatus;
import com.openbag.enums.OrderStatus;
import com.openbag.enums.ShiftMode;
import com.openbag.exception.BadRequestException;
import com.openbag.exception.ResourceNotFoundException;
import com.openbag.modules.delivery.dispatch.DispatchProperties;
import com.openbag.modules.delivery.dispatch.DispatchRequestedEvent;
import com.openbag.modules.delivery.dispatch.DispatchService;
import com.openbag.modules.delivery.dto.*;
import com.openbag.modules.delivery.entity.CourierShift;
import com.openbag.modules.delivery.entity.DeliveryOffer;
import com.openbag.modules.delivery.entity.DeliveryPerson;
import com.openbag.modules.delivery.repository.CourierShiftRepository;
import com.openbag.modules.delivery.repository.DeliveryOfferRepository;
import com.openbag.modules.delivery.repository.DeliveryPersonRepository;
import com.openbag.modules.delivery.repository.RestaurantCourierLinkRepository;
import com.openbag.modules.delivery.tracking.CourierTracking;
import com.openbag.modules.order.entity.Order;
import com.openbag.modules.order.realtime.CourierLocationEvent;
import com.openbag.modules.order.realtime.OrderChangedEvent;
import com.openbag.modules.order.repository.OrderRepository;
import com.openbag.modules.order.service.OrderService;
import com.openbag.modules.order.service.RestaurantOrderService;
import com.openbag.modules.organization.entity.Organization;
import com.openbag.modules.restaurant.entity.Restaurant;
import com.openbag.modules.restaurant.repository.RestaurantRepository;
import com.openbag.modules.shared.util.GeoUtils;
import com.openbag.modules.user.entity.User;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.List;
import java.util.Locale;

/**
 * Trabalho do entregador: ficar online (modo livre), check-in no restaurante (modo fixo), responder ofertas,
 * retirar e entregar.
 */
@Service
@Transactional
@Slf4j
public class CourierWorkService {

    // Pedido aceito pelo entregador e ainda não entregue
    private static final EnumSet<OrderStatus> IN_PROGRESS = EnumSet.of(OrderStatus.CONFIRMED, OrderStatus.PREPARING,
            OrderStatus.READY_FOR_PICKUP, OrderStatus.OUT_FOR_DELIVERY);

    @Autowired
    private DeliveryPersonRepository deliveryPersonRepository;

    @Autowired
    private CourierShiftRepository shiftRepository;

    @Autowired
    private DeliveryOfferRepository offerRepository;

    @Autowired
    private RestaurantCourierLinkRepository linkRepository;

    @Autowired
    private RestaurantRepository restaurantRepository;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private OrderService orderService;

    @Autowired
    private RestaurantOrderService restaurantOrderService;

    @Autowired
    private DispatchService dispatchService;

    @Autowired
    private DispatchProperties properties;

    @Autowired
    private ApplicationEventPublisher events;

    @Autowired
    private Clock clock;

    // ============= Situação =============

    @Transactional(readOnly = true)
    public CourierWorkStateDTO getState(User user) {
        return toState(findCourier(user));
    }

    public CourierWorkStateDTO goOnline(User user, LocationRequest location) {
        DeliveryPerson courier = lockCourier(user);
        requireCanWork(courier);
        CourierShift current = openShift(courier);
        if (current != null && current.getMode() == ShiftMode.FIXED) {
            throw new BadRequestException("Você está em check-in em um restaurante. Faça o check-out antes de ficar online.");
        }
        updatePosition(courier, location);
        if (current == null) {
            startShift(courier, ShiftMode.FREE, null, location);
        }
        if (courier.getWorkStatus() == CourierWorkStatus.OFFLINE) {
            courier.setWorkStatus(CourierWorkStatus.ONLINE);
        }
        courier.setAvailable(true);
        deliveryPersonRepository.save(courier);
        log.info("Entregador {} ficou online", courier.getId());
        return toState(courier);
    }

    public CourierWorkStateDTO goOffline(User user) {
        DeliveryPerson courier = lockCourier(user);
        endCurrentShift(courier, "Você ficou offline");
        log.info("Entregador {} ficou offline", courier.getId());
        return toState(courier);
    }

    /**
     * Posição enviada pelo app enquanto online. Vai também para o cliente da entrega que está na vez.
     */
    public void updateLocation(User user, LocationRequest location) {
        DeliveryPerson courier = findCourier(user);
        LocalDateTime now = LocalDateTime.now(clock);
        // Só a posição: salvar o entregador inteiro desfaria um aceite gravado ao mesmo tempo
        deliveryPersonRepository.updateLocation(courier.getId(), location.getLatitude(), location.getLongitude(), now);
        CourierTracking.currentStop(ordersOnTheWay(courier)).ifPresent(order ->
                events.publishEvent(new CourierLocationEvent(order.getId(), location.getLatitude(),
                        location.getLongitude(), now)));
    }

    /**
     * Check-in no restaurante em que o entregador é fixo: precisa estar perto dele. Durante o turno fixo o
     * entregador só recebe pedidos deste restaurante.
     */
    public CourierWorkStateDTO checkIn(User user, Long restaurantId, LocationRequest location) {
        DeliveryPerson courier = lockCourier(user);
        requireCanWork(courier);
        Restaurant restaurant = restaurantRepository.findById(restaurantId)
                .orElseThrow(() -> new ResourceNotFoundException("Restaurante não encontrado"));
        if (!linkRepository.existsByRestaurantIdAndDeliveryPersonIdAndStatus(restaurantId, courier.getId(),
                CourierLinkStatus.ACTIVE)) {
            throw new BadRequestException("Você não é entregador fixo deste restaurante");
        }
        if (restaurant.getLatitude() != null && restaurant.getLongitude() != null) {
            double meters = 1000 * GeoUtils.haversineKm(location.getLatitude(), location.getLongitude(),
                    restaurant.getLatitude().doubleValue(), restaurant.getLongitude().doubleValue());
            if (meters > properties.getCheckinRadiusMeters()) {
                throw new BadRequestException(String.format(Locale.ROOT,
                        "Você está a %.0f m do restaurante. Chegue mais perto (até %.0f m) para fazer o check-in.",
                        meters, properties.getCheckinRadiusMeters()));
            }
        }

        CourierShift current = openShift(courier);
        if (current != null) {
            if (current.getMode() == ShiftMode.FIXED && current.getRestaurant().getId().equals(restaurantId)) {
                return toState(courier);
            }
            if (courier.getWorkStatus() == CourierWorkStatus.BUSY) {
                throw new BadRequestException("Termine a entrega em andamento antes de fazer check-in");
            }
            endCurrentShift(courier, "Você fez check-in em um restaurante");
        }
        updatePosition(courier, location);
        startShift(courier, ShiftMode.FIXED, restaurant, location);
        courier.setWorkStatus(CourierWorkStatus.ONLINE);
        courier.setAvailable(true);
        deliveryPersonRepository.save(courier);
        log.info("Entregador {} fez check-in no restaurante {}", courier.getId(), restaurantId);
        return toState(courier);
    }

    public CourierWorkStateDTO checkOut(User user) {
        DeliveryPerson courier = lockCourier(user);
        CourierShift current = openShift(courier);
        if (current == null || current.getMode() != ShiftMode.FIXED) {
            throw new BadRequestException("Você não está em check-in em nenhum restaurante");
        }
        endCurrentShift(courier, "Você fez check-out");
        return toState(courier);
    }

    // ============= Ofertas =============

    public CourierWorkStateDTO acceptOffer(User user, Long offerId) {
        // Ordem das travas, a mesma do resto do despacho: pedidos (em ordem de id) e depois o entregador.
        // Travar o entregador primeiro dava deadlock com a loja atribuindo o mesmo pedido a ele.
        Long orderId = lockOfferOrders(user, offerId);
        DeliveryPerson courier = lockCourier(user);
        // A oferta é lida depois das travas: a expiração e a recusa mexem nela com o pedido ou o entregador travado
        DeliveryOffer offer = offerRepository.findByIdAndDeliveryPersonId(offerId, courier.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Oferta não encontrada"));
        if (offer.getStatus() == DeliveryOfferStatus.ACCEPTED) {
            // Toque duplo ou nova tentativa depois de um timeout: o aceite já valeu, devolve a entrega dele
            return toState(courier);
        }
        LocalDateTime now = LocalDateTime.now(clock);
        if (offer.getStatus() != DeliveryOfferStatus.PENDING || now.isAfter(offer.getExpiresAt())) {
            throw new BadRequestException("Esta oferta não está mais disponível");
        }
        if (courier.getWorkStatus() != CourierWorkStatus.ONLINE) {
            throw new BadRequestException("Você precisa estar online para aceitar entregas");
        }

        Order order = orderRepository.findByIdForUpdate(orderId).orElseThrow();
        if (order.getDeliveryPerson() != null || order.getStaffCourier() != null
                || !DispatchService.DISPATCHABLE.contains(order.getStatus())) {
            offer.setStatus(DeliveryOfferStatus.CANCELLED);
            offer.setRespondedAt(now);
            offerRepository.save(offer);
            throw new BadRequestException("Este pedido não está mais disponível");
        }

        List<Order> assigned = dispatchService.assignOfferedOrders(offer, courier, now);

        offer.setStatus(DeliveryOfferStatus.ACCEPTED);
        offer.setRespondedAt(now);
        offerRepository.save(offer);

        courier.setWorkStatus(CourierWorkStatus.BUSY);
        courier.setAvailable(false);
        deliveryPersonRepository.save(courier);

        assigned.forEach(o -> events.publishEvent(new OrderChangedEvent(o.getId(), OrderChangedEvent.Type.ORDER_UPDATED)));
        log.info("Entregador {} aceitou {} (R$ {})", courier.getId(),
                offer.getRoute() != null ? "a rota " + offer.getRoute().getId() + " com " + assigned.size() + " pedidos"
                        : "o pedido " + order.getId(), offer.getCourierFee());
        return toState(courier);
    }

    public CourierWorkStateDTO declineOffer(User user, Long offerId) {
        DeliveryPerson courier = lockCourier(user);
        DeliveryOffer offer = offerRepository.findByIdAndDeliveryPersonId(offerId, courier.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Oferta não encontrada"));
        if (offer.getStatus() == DeliveryOfferStatus.PENDING) {
            offer.setStatus(DeliveryOfferStatus.DECLINED);
            offer.setRespondedAt(LocalDateTime.now(clock));
            offerRepository.save(offer);
            events.publishEvent(new DispatchRequestedEvent(offer.getOrder().getId()));
        }
        return toState(courier);
    }

    // ============= Entrega =============

    public CourierWorkStateDTO pickUp(User user, Long orderId) {
        DeliveryPerson courier = findCourier(user);
        Order order = findAssignedOrder(courier, orderId);
        if (order.getStatus() == OrderStatus.CONFIRMED || order.getStatus() == OrderStatus.PREPARING) {
            throw new BadRequestException("O restaurante ainda não marcou o pedido como pronto");
        }
        restaurantOrderService.advance(order, EnumSet.of(OrderStatus.READY_FOR_PICKUP), OrderStatus.OUT_FOR_DELIVERY,
                "Entregador retirou o pedido e saiu para entrega", (o, now) -> {
                    o.setDispatchedAt(now);
                    o.setPickedUpAt(now);
                });
        return toState(courier);
    }

    public CourierWorkStateDTO deliver(User user, Long orderId) {
        DeliveryPerson courier = findCourier(user);
        Order order = findAssignedOrder(courier, orderId);
        restaurantOrderService.advance(order, EnumSet.of(OrderStatus.OUT_FOR_DELIVERY), OrderStatus.DELIVERED,
                "Pedido entregue", (o, now) -> {
                    o.setDeliveredAt(now);
                    o.setPaymentStatus(Order.PaymentStatus.PAID);
                });
        // Próxima entrega da rota: o cliente dela passa a ver o entregador no mapa
        CourierTracking.currentStop(ordersOnTheWay(courier).stream()
                        .filter(o -> !o.getId().equals(orderId)).toList())
                .ifPresent(next -> events.publishEvent(new OrderChangedEvent(next.getId(), OrderChangedEvent.Type.ORDER_UPDATED)));
        // Liberação do entregador e contadores: DispatchService, depois do commit
        return toState(courier);
    }

    // ============= Consultas usadas por outros serviços =============

    @Transactional(readOnly = true)
    public boolean isCheckedInAt(DeliveryPerson courier, Long restaurantId) {
        CourierShift shift = courier.getCurrentShift();
        return shift != null && shift.isOpen() && shift.getMode() == ShiftMode.FIXED
                && shift.getRestaurant() != null && shift.getRestaurant().getId().equals(restaurantId);
    }

    /**
     * Encerra o check-in do entregador no restaurante (vínculo de fixo encerrado)
     */
    public void endFixedShiftAt(DeliveryPerson courier, Long restaurantId) {
        if (isCheckedInAt(courier, restaurantId)) {
            DeliveryPerson locked = deliveryPersonRepository.findByIdForUpdate(courier.getId()).orElseThrow();
            if (locked.getWorkStatus() == CourierWorkStatus.BUSY) {
                // Termina a entrega em andamento; o turno fecha como livre-de-ofertas
                locked.getCurrentShift().setEndedAt(LocalDateTime.now(clock));
                shiftRepository.save(locked.getCurrentShift());
                return;
            }
            endCurrentShift(locked, "Seu vínculo com o restaurante foi encerrado");
        }
    }

    // ============= Auxiliares =============

    private void requireCanWork(DeliveryPerson courier) {
        List<String> blockers = blockers(courier);
        if (!blockers.isEmpty()) {
            throw new BadRequestException(blockers.get(0));
        }
    }

    /**
     * O que impede o entregador de receber entregas agora
     */
    private List<String> blockers(DeliveryPerson courier) {
        List<String> blockers = new ArrayList<>();
        Organization organization = courier.getOrganization();
        if (!courier.isActive() || organization == null) {
            blockers.add("Você precisa ter um vínculo ativo com uma associação para receber entregas");
        } else if (!organization.isOperational()) {
            blockers.add("Sua associação não está ativa na plataforma");
        } else if (!organization.isDeliveryRateConfigured()) {
            blockers.add("Sua associação ainda não definiu a tabela de valores de entrega");
        }
        if (courier.getActiveVehicle() == null) {
            blockers.add("Cadastre o veículo que você usa nas entregas");
        }
        return blockers;
    }

    private void startShift(DeliveryPerson courier, ShiftMode mode, Restaurant restaurant, LocationRequest location) {
        CourierShift shift = new CourierShift();
        shift.setDeliveryPerson(courier);
        shift.setMode(mode);
        shift.setRestaurant(restaurant);
        shift.setVehicle(courier.getActiveVehicle());
        shift.setStartedAt(LocalDateTime.now(clock));
        shift.setStartLatitude(location.getLatitude());
        shift.setStartLongitude(location.getLongitude());
        courier.setCurrentShift(shiftRepository.save(shift));
    }

    /**
     * Encerra o turno aberto. Com entrega em andamento não é possível; a oferta pendente passa para o próximo.
     */
    private void endCurrentShift(DeliveryPerson courier, String reason) {
        if (courier.getWorkStatus() == CourierWorkStatus.BUSY) {
            throw new BadRequestException("Termine a entrega em andamento antes de sair");
        }
        dispatchService.declinePendingOffer(courier, reason);
        CourierShift shift = openShift(courier);
        if (shift != null) {
            shift.setEndedAt(LocalDateTime.now(clock));
            shiftRepository.save(shift);
        }
        courier.setCurrentShift(null);
        courier.setWorkStatus(CourierWorkStatus.OFFLINE);
        courier.setAvailable(false);
        deliveryPersonRepository.save(courier);
    }

    private static CourierShift openShift(DeliveryPerson courier) {
        CourierShift shift = courier.getCurrentShift();
        return shift != null && shift.isOpen() ? shift : null;
    }

    private void updatePosition(DeliveryPerson courier, LocationRequest location) {
        courier.setLastLatitude(location.getLatitude());
        courier.setLastLongitude(location.getLongitude());
        courier.setLastSeenAt(LocalDateTime.now(clock));
    }

    private List<Order> ordersOnTheWay(DeliveryPerson courier) {
        return orderRepository.findByCourierAndStatusIn(courier.getId(), EnumSet.of(OrderStatus.OUT_FOR_DELIVERY));
    }

    private Order findAssignedOrder(DeliveryPerson courier, Long orderId) {
        return orderRepository.findByIdForUpdate(orderId)
                .filter(o -> o.getDeliveryPerson() != null && o.getDeliveryPerson().getId().equals(courier.getId()))
                .orElseThrow(() -> new ResourceNotFoundException("Entrega não encontrada"));
    }

    /**
     * Trava o pedido da oferta ou, numa rota, todos os pedidos dela, em ordem de id. Devolve o pedido da oferta.
     */
    private Long lockOfferOrders(User user, Long offerId) {
        Object[] row = offerRepository.findOrderAndRouteOfCourierOffer(offerId, user.getId()).stream()
                .findFirst()
                .orElseThrow(() -> new ResourceNotFoundException("Oferta não encontrada"));
        Long orderId = (Long) row[0];
        Long routeId = (Long) row[1];
        java.util.Set<Long> ids = new java.util.TreeSet<>();
        ids.add(orderId);
        if (routeId != null) {
            ids.addAll(orderRepository.findIdsByRouteId(routeId));
        }
        orderRepository.findAllByIdForUpdate(ids);
        return orderId;
    }

    private CourierWorkStateDTO toState(DeliveryPerson courier) {
        LocalDateTime now = LocalDateTime.now(clock);
        LocalDate today = now.toLocalDate();
        CourierShift shift = openShift(courier);

        BigDecimal earned = orderRepository.sumCourierFeesBetween(List.of(courier.getId()), today.atStartOfDay(),
                        today.plusDays(1).atStartOfDay()).stream()
                .map(row -> (BigDecimal) row[1])
                .findFirst()
                .orElse(BigDecimal.ZERO);

        // Rota: na ordem de entrega (entregues somem da lista)
        List<CourierOrderDTO> active = orderRepository.findByCourierAndStatusIn(courier.getId(), IN_PROGRESS).stream()
                .sorted(java.util.Comparator
                        .comparing((Order o) -> o.getRouteSequence() != null ? o.getRouteSequence() : Integer.MAX_VALUE)
                        .thenComparing(Order::getAssignedAt, java.util.Comparator.nullsLast(java.util.Comparator.naturalOrder())))
                .map(CourierOrderDTO::from)
                .toList();

        return CourierWorkStateDTO.builder()
                .deliveryPersonId(courier.getId())
                .workStatus(courier.getWorkStatus())
                .shift(shift == null ? null : CourierWorkStateDTO.Shift.builder()
                        .id(shift.getId())
                        .mode(shift.getMode())
                        .restaurant(shift.getRestaurant() != null
                                ? CourierLinkDTO.restaurantInfo(shift.getRestaurant()) : null)
                        .vehicle(shift.getVehicle() != null ? VehicleDTO.from(shift.getVehicle(), true) : null)
                        .startedAt(shift.getStartedAt())
                        .deliveriesCount(shift.getDeliveriesCount())
                        .build())
                .pendingOffer(offerRepository.findPendingByCourier(courier.getId())
                        .map(offer -> CourierOfferDTO.from(offer, now))
                        .orElse(null))
                .activeOrder(active.isEmpty() ? null : active.get(0))
                .activeOrders(active)
                .earnedToday(earned)
                .deliveriesToday((int) orderRepository.countDeliveredBetween(courier.getId(), today.atStartOfDay(),
                        today.plusDays(1).atStartOfDay()))
                .blockers(blockers(courier))
                .build();
    }

    private DeliveryPerson findCourier(User user) {
        return deliveryPersonRepository.findByUserId(user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Perfil de entregador não encontrado"));
    }

    private DeliveryPerson lockCourier(User user) {
        DeliveryPerson courier = deliveryPersonRepository.findByUserIdForUpdate(user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Perfil de entregador não encontrado"));
        return courier;
    }
}
