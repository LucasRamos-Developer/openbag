package com.openbag.modules.delivery.dispatch;

import com.openbag.enums.CourierPolicy;
import com.openbag.enums.CourierWorkStatus;
import com.openbag.enums.DeliveryOfferStatus;
import com.openbag.enums.OrderStatus;
import com.openbag.enums.RouteStatus;
import com.openbag.exception.BadRequestException;
import com.openbag.exception.ResourceNotFoundException;
import com.openbag.modules.delivery.dispatch.CourierSelector.Candidate;
import com.openbag.modules.delivery.dispatch.CourierSelector.Choice;
import com.openbag.modules.delivery.dispatch.ReassignPolicy.CourierKind;
import com.openbag.modules.delivery.dispatch.ReassignPolicy.Decision;
import com.openbag.modules.delivery.dto.AssignCourierRequest;
import com.openbag.modules.delivery.dto.CourierMessage;
import com.openbag.modules.delivery.dto.CourierOptionsDTO;
import com.openbag.modules.delivery.dto.CourierOfferDTO;
import com.openbag.modules.delivery.dto.CourierOrderDTO;
import com.openbag.modules.delivery.entity.CourierShift;
import com.openbag.modules.delivery.entity.DeliveryOffer;
import com.openbag.modules.delivery.entity.DeliveryPerson;
import com.openbag.modules.delivery.entity.DeliveryRoute;
import com.openbag.modules.delivery.entity.StaffCourier;
import com.openbag.modules.delivery.repository.CourierShiftRepository;
import com.openbag.modules.delivery.repository.DeliveryOfferRepository;
import com.openbag.modules.delivery.repository.DeliveryPersonRepository;
import com.openbag.modules.delivery.repository.DeliveryRouteRepository;
import com.openbag.modules.delivery.repository.RestaurantPartnershipRepository;
import com.openbag.modules.delivery.repository.StaffCourierRepository;
import com.openbag.modules.delivery.service.DeliveryRateCalculator;
import com.openbag.modules.order.entity.Order;
import com.openbag.modules.order.realtime.OrderChangedEvent;
import com.openbag.modules.order.repository.OrderRepository;
import com.openbag.modules.order.service.OrderService;
import com.openbag.modules.organization.entity.Organization;
import com.openbag.modules.restaurant.entity.Restaurant;
import com.openbag.modules.shared.util.GeoUtils;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;
import org.springframework.transaction.support.TransactionTemplate;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.function.Consumer;

/**
 * Despacho das entregas: escolhe o entregador, cria a oferta com prazo, repassa ao próximo quando ela é recusada
 * ou expira, e libera o entregador quando a entrega termina ou o pedido é cancelado.
 *
 * O pedido entra no despacho quando o restaurante o aceita (o entregador chega enquanto a comida é preparada).
 * Primeiro são tentados os fixos em check-in no restaurante; depois, se a política permitir, o modo livre.
 */
@Service
@Slf4j
public class DispatchService {

    public static final Set<OrderStatus> DISPATCHABLE =
            EnumSet.of(OrderStatus.CONFIRMED, OrderStatus.PREPARING, OrderStatus.READY_FOR_PICKUP);

    /** Entregas abertas de um entregador (atribuídas e ainda não concluídas) */
    public static final Set<OrderStatus> ACTIVE_FOR_COURIER = EnumSet.of(OrderStatus.CONFIRMED, OrderStatus.PREPARING,
            OrderStatus.READY_FOR_PICKUP, OrderStatus.OUT_FOR_DELIVERY);

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private DeliveryPersonRepository deliveryPersonRepository;

    @Autowired
    private DeliveryOfferRepository offerRepository;

    @Autowired
    private CourierShiftRepository shiftRepository;

    @Autowired
    private RestaurantPartnershipRepository partnershipRepository;

    @Autowired
    private StaffCourierRepository staffRepository;

    @Autowired
    private DeliveryRouteRepository routeRepository;

    @Autowired
    private OrderService orderService;

    @Autowired
    private CourierNotifier notifier;

    @Autowired
    private DispatchProperties properties;

    @Autowired
    private ApplicationEventPublisher events;

    @Autowired
    private Clock clock;

    private final TransactionTemplate newTransaction;

    public DispatchService(PlatformTransactionManager transactionManager) {
        this.newTransaction = new TransactionTemplate(transactionManager);
        this.newTransaction.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
    }

    // ============= Eventos =============

    /**
     * Toda mudança de pedido: libera o entregador ao fim da entrega, cancela ofertas que não fazem mais sentido,
     * avisa o entregador atribuído e, se o pedido ainda espera entregador, oferece a alguém.
     */
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void onOrderChanged(OrderChangedEvent event) {
        orderRepository.findByIdForUpdate(event.orderId()).ifPresent(this::handleOrderChange);
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void onDispatchRequested(DispatchRequestedEvent event) {
        orderRepository.findByIdForUpdate(event.orderId()).ifPresent(this::dispatchLocked);
    }

    private void handleOrderChange(Order order) {
        OrderStatus status = order.getStatus();
        if (status == OrderStatus.CANCELLED) {
            closePendingOffers(order, "O pedido foi cancelado");
            settleCourier(order, false);
            DeliveryRoute route = order.getRoute();
            if (route != null) {
                leaveRoute(order);
                // A rota continua com os outros pedidos: se ainda procura entregador, oferece de novo
                if (route.getStatus() == RouteStatus.DISPATCHING) {
                    dispatchRoute(route);
                }
            }
            return;
        }
        if (status == OrderStatus.DELIVERED) {
            closePendingOffers(order, "O pedido já foi entregue");
            settleCourier(order, true);
            updateRouteProgress(order.getRoute());
            return;
        }
        if (status == OrderStatus.OUT_FOR_DELIVERY) {
            updateRouteProgress(order.getRoute());
        }
        if (order.getDeliveryPerson() != null) {
            notifier.send(order.getDeliveryPerson().getId(),
                    new CourierMessage(CourierMessage.Type.ORDER_UPDATED, null, CourierOrderDTO.from(order), null));
        }
        if (!DISPATCHABLE.contains(status)) {
            // Saiu para entrega sem entregador do app (equipe própria do restaurante)
            closePendingOffers(order, "O restaurante despachou o pedido");
            return;
        }
        if (order.getDeliveryPerson() == null && order.getStaffCourier() == null) {
            dispatchLocked(order);
        }
    }

    // ============= Jobs =============

    /**
     * Ofertas sem resposta no prazo: expiram e o pedido vai para o próximo entregador
     */
    @Scheduled(fixedDelayString = "${app.delivery.offer-check-ms:5000}", initialDelay = 15000)
    public void expireOffers() {
        LocalDateTime now = LocalDateTime.now(clock);
        for (DeliveryOffer expired : offerRepository.findExpired(now)) {
            inNewTransaction(expired.getOrder().getId(), order -> {
                DeliveryOffer offer = offerRepository.findById(expired.getId()).orElseThrow();
                if (offer.getStatus() != DeliveryOfferStatus.PENDING) {
                    return;
                }
                offer.setStatus(DeliveryOfferStatus.EXPIRED);
                offer.setRespondedAt(LocalDateTime.now(clock));
                offerRepository.save(offer);
                notifyClosed(offer, "O tempo para aceitar acabou");
                log.info("Oferta {} do pedido {} expirou (entregador {})", offer.getId(), order.getId(),
                        offer.getDeliveryPerson().getId());
                dispatchLocked(order);
            });
        }
    }

    /**
     * Pedidos que continuam sem entregador: nova tentativa (alguém pode ter ficado online ou terminado uma entrega)
     */
    @Scheduled(fixedDelayString = "${app.delivery.retry-ms:15000}", initialDelay = 20000)
    public void retryWaitingOrders() {
        for (Long orderId : orderRepository.findIdsAwaitingCourier(DISPATCHABLE)) {
            inNewTransaction(orderId, this::dispatchLocked);
        }
    }

    /**
     * Turnos livres sem sinal de localização há muito tempo são encerrados (app fechado)
     */
    @Scheduled(fixedDelayString = "${app.delivery.stale-shift-check-ms:60000}", initialDelay = 60000)
    public void closeStaleShifts() {
        LocalDateTime now = LocalDateTime.now(clock);
        LocalDateTime before = now.minusMinutes(properties.getShiftTimeoutMinutes());
        for (CourierShift stale : shiftRepository.findStaleFreeShifts(before)) {
            newTransaction.executeWithoutResult(tx -> {
                DeliveryPerson courier = deliveryPersonRepository.findByIdForUpdate(stale.getDeliveryPerson().getId())
                        .orElseThrow();
                CourierShift shift = courier.getCurrentShift();
                if (shift == null || !shift.getId().equals(stale.getId()) || courier.getWorkStatus() != CourierWorkStatus.ONLINE) {
                    return;
                }
                declinePendingOffer(courier, "Você ficou offline por falta de sinal");
                shift.setEndedAt(now);
                courier.setCurrentShift(null);
                courier.setWorkStatus(CourierWorkStatus.OFFLINE);
                courier.setAvailable(false);
                deliveryPersonRepository.save(courier);
                notifier.send(courier.getId(), new CourierMessage(CourierMessage.Type.STATE_CHANGED, null, null,
                        "Você ficou offline porque o app parou de enviar a localização"));
                log.info("Turno {} do entregador {} encerrado por falta de sinal", shift.getId(), courier.getId());
            });
        }
    }

    // ============= Operações usadas por outros serviços =============

    // ============= Atribuição pela loja =============

    /**
     * Quem pode levar o pedido agora (fixos em check-in, livres online por perto e equipe própria) e se a loja
     * pode trocar quem está com ele
     */
    @Transactional
    public CourierOptionsDTO courierOptions(Long restaurantId, Long orderId) {
        Order order = orderRepository.findByIdAndRestaurantId(orderId, restaurantId)
                .orElseThrow(() -> new ResourceNotFoundException("Pedido não encontrado"));
        ensureDeliveryDistance(order);
        LocalDateTime now = LocalDateTime.now(clock);
        Restaurant restaurant = order.getRestaurant();
        Long currentCourierId = order.getDeliveryPerson() != null ? order.getDeliveryPerson().getId() : null;
        Long currentStaffId = order.getStaffCourier() != null ? order.getStaffCourier().getId() : null;

        List<CourierOptionsDTO.Option> options = new ArrayList<>();
        Set<Long> listed = new HashSet<>();
        for (CourierShift shift : shiftRepository.findOpenFixedAtRestaurant(restaurantId)) {
            DeliveryPerson courier = shift.getDeliveryPerson();
            if (!courier.getId().equals(currentCourierId) && listed.add(courier.getId())) {
                options.add(appOption(CourierKind.FIXED, courier, order));
            }
        }
        LocalDateTime seenSince = now.minusSeconds(properties.getLocationStaleSeconds());
        for (DeliveryPerson courier : deliveryPersonRepository.findFreeOnlineCouriers(seenSince)) {
            Double pickupKm = pickupDistance(courier, restaurant);
            if (courier.getId().equals(currentCourierId) || !listed.add(courier.getId())
                    || (pickupKm != null && pickupKm > properties.getSearchRadiusKm())) {
                continue;
            }
            options.add(appOption(CourierKind.FREE, courier, order));
        }
        for (StaffCourier staff : staffRepository.findByRestaurantIdAndActiveTrueOrderByNameAsc(restaurantId)) {
            if (!staff.getId().equals(currentStaffId)) {
                options.add(new CourierOptionsDTO.Option(CourierKind.STAFF, null, staff.getId(), staff.getName(), null,
                        null, null, staffFee(staff, order), null));
            }
        }
        // Disponíveis primeiro; depois fixos, livres (mais perto antes) e equipe
        options.sort(Comparator.comparing((CourierOptionsDTO.Option o) -> o.blockedReason() != null)
                .thenComparing(CourierOptionsDTO.Option::kind)
                .thenComparing(CourierOptionsDTO.Option::distanceKm, Comparator.nullsLast(Comparator.naturalOrder())));

        CourierOptionsDTO.Current current = null;
        CourierKind kind = ReassignPolicy.kindOf(order);
        if (kind != null) {
            Decision decision = ReassignPolicy.decide(order, now, properties.getLocationStaleSeconds());
            current = new CourierOptionsDTO.Current(kind, courierName(order), decision.allowed(), decision.reason(),
                    decision.availableAt(), decision.courierAtStore());
        }
        return new CourierOptionsDTO(current, options);
    }

    /**
     * A loja entrega o pedido direto a um entregador do app ou da equipe própria, sem oferta. Se já havia alguém
     * com o pedido, a troca segue a {@link ReassignPolicy}.
     */
    @Transactional
    public void assignDirect(Long restaurantId, Long orderId, AssignCourierRequest request) {
        if ((request.deliveryPersonId() == null) == (request.staffCourierId() == null)) {
            throw new BadRequestException("Escolha um entregador");
        }
        Order order = lockRestaurantOrder(restaurantId, orderId);
        if (!DISPATCHABLE.contains(order.getStatus())) {
            throw new BadRequestException("Este pedido não pode mais receber entregador");
        }
        if (isCurrent(order, request)) {
            return;
        }
        LocalDateTime now = LocalDateTime.now(clock);
        assertCanReassign(order, now);
        ensureDeliveryDistance(order);
        // Escolher entregador para um pedido de rota tira o pedido da rota (sai sozinho)
        if (order.getRoute() != null) {
            closePendingOffers(order, "A loja escolheu outro entregador");
            leaveRoute(order);
            order.setSoloDispatch(true);
        }

        if (request.staffCourierId() != null) {
            StaffCourier staff = staffRepository.findByIdAndRestaurantId(request.staffCourierId(), restaurantId)
                    .filter(StaffCourier::isActive)
                    .orElseThrow(() -> new ResourceNotFoundException("Entregador da equipe não encontrado"));
            closePendingOffers(order, "A loja escolheu outro entregador");
            releaseCurrent(order, "A loja passou o pedido para outro entregador");
            order.setStaffCourier(staff);
            order.setCourierFee(staffFee(staff, order));
            order.setRestaurantDeliverySubsidy(BigDecimal.ZERO);
            orderService.addTracking(order, order.getStatus(), "Entregador definido: " + staff.getName(), now);
        } else {
            DeliveryPerson courier = deliveryPersonRepository.findByIdForUpdate(request.deliveryPersonId())
                    .orElseThrow(() -> new ResourceNotFoundException("Entregador não encontrado"));
            String blocked = blockedReason(courier, order);
            if (blocked != null) {
                throw new BadRequestException(blocked);
            }
            BigDecimal fee = courierFee(courier, order);
            closePendingOffers(order, "A loja escolheu outro entregador");
            declinePendingOffer(courier, "A loja te passou outro pedido");
            releaseCurrent(order, "A loja passou o pedido para outro entregador");

            order.setDeliveryPerson(courier);
            order.setCourierFee(fee);
            order.setRestaurantDeliverySubsidy(DeliveryRateCalculator.subsidy(fee, order.getDeliveryFee()));
            courier.setWorkStatus(CourierWorkStatus.BUSY);
            courier.setAvailable(false);
            deliveryPersonRepository.save(courier);
            orderService.addTracking(order, order.getStatus(), "Entregador definido: " + courier.getUser().getFullName(), now);
        }
        order.setAssignedAt(now);
        order.setSearchingCourierSince(null);
        orderRepository.save(order);
        if (order.getDeliveryPerson() != null) {
            notifier.send(order.getDeliveryPerson().getId(), new CourierMessage(CourierMessage.Type.ORDER_ASSIGNED,
                    null, CourierOrderDTO.from(order), "A loja te passou o pedido " + order.getDisplayCode()));
        }
        events.publishEvent(new OrderChangedEvent(order.getId(), OrderChangedEvent.Type.ORDER_UPDATED));
        log.info("Restaurante {} atribuiu o pedido {} a {}", restaurantId, orderId, courierName(order));
    }

    /**
     * A loja entrega a rota inteira a um entregador, sem oferta. Troca de quem já está com ela segue a regra do
     * pedido líder ({@link ReassignPolicy}).
     */
    @Transactional
    public void assignRouteDirect(Long restaurantId, Long routeId, AssignCourierRequest request) {
        if ((request.deliveryPersonId() == null) == (request.staffCourierId() == null)) {
            throw new BadRequestException("Escolha um entregador");
        }
        DeliveryRoute route = routeRepository.findByIdAndRestaurantId(routeId, restaurantId)
                .orElseThrow(() -> new ResourceNotFoundException("Rota não encontrada"));
        List<Order> orders = new ArrayList<>();
        for (Order order : route.sortedOrders()) {
            if (DISPATCHABLE.contains(order.getStatus())) {
                orders.add(orderRepository.findByIdForUpdate(order.getId()).orElseThrow());
            }
        }
        if (orders.isEmpty() || orders.stream().anyMatch(o -> o.getPickedUpAt() != null)) {
            throw new BadRequestException("Esta rota já saiu para entrega");
        }
        LocalDateTime now = LocalDateTime.now(clock);
        Order lead = orders.get(0);
        assertCanReassign(lead, now);
        orders.forEach(this::ensureDeliveryDistance);

        StaffCourier staff = null;
        DeliveryPerson courier = null;
        if (request.staffCourierId() != null) {
            staff = staffRepository.findByIdAndRestaurantId(request.staffCourierId(), restaurantId)
                    .filter(StaffCourier::isActive)
                    .orElseThrow(() -> new ResourceNotFoundException("Entregador da equipe não encontrado"));
        } else {
            courier = deliveryPersonRepository.findByIdForUpdate(request.deliveryPersonId())
                    .orElseThrow(() -> new ResourceNotFoundException("Entregador não encontrado"));
            boolean alreadyHasRoute = courier.equals(route.getDeliveryPerson());
            for (Order order : orders) {
                String blocked = alreadyHasRoute ? null : blockedReason(courier, order);
                if (blocked != null) {
                    throw new BadRequestException(blocked + " (pedido " + order.getDisplayCode() + ")");
                }
            }
            declinePendingOffer(courier, "A loja te passou uma rota");
        }
        closePendingOffers(lead, "A loja escolheu outro entregador");
        for (Order order : orders) {
            releaseCurrent(order, "A loja passou a rota para outro entregador");
            applyAssignment(order, courier, staff, now);
            orderRepository.save(order);
        }
        route.setDeliveryPerson(courier);
        route.setStaffCourier(staff);
        route.setStatus(RouteStatus.ASSIGNED);
        route.setDispatchedAt(route.getDispatchedAt() != null ? route.getDispatchedAt() : now);
        routeRepository.save(route);
        if (courier != null) {
            courier.setWorkStatus(CourierWorkStatus.BUSY);
            courier.setAvailable(false);
            deliveryPersonRepository.save(courier);
            notifier.send(courier.getId(), new CourierMessage(CourierMessage.Type.ORDER_ASSIGNED, null,
                    CourierOrderDTO.from(lead), "A loja te passou uma rota com " + orders.size() + " entregas"));
        }
        orders.forEach(o -> events.publishEvent(new OrderChangedEvent(o.getId(), OrderChangedEvent.Type.ORDER_UPDATED)));
        log.info("Restaurante {} atribuiu a rota {} ({} pedidos) a {}", restaurantId, routeId, orders.size(),
                courierName(lead));
    }

    /**
     * Entregador aceitou a oferta: ele fica com o pedido (ou com todos os pedidos da rota que ainda esperam),
     * cada um com o valor da tabela da associação dele
     */
    public List<Order> assignOfferedOrders(DeliveryOffer offer, DeliveryPerson courier, LocalDateTime now) {
        DeliveryRoute route = offer.getRoute();
        List<Order> orders = new ArrayList<>();
        if (route == null) {
            orders.add(offer.getOrder());
        } else {
            for (Order order : waitingOrders(route)) {
                orders.add(orderRepository.findByIdForUpdate(order.getId()).orElseThrow());
            }
        }
        for (Order order : orders) {
            applyAssignment(order, courier, null, now);
            if (route == null) {
                // Pedido sozinho: vale o valor da oferta
                order.setCourierFee(offer.getCourierFee());
                order.setRestaurantDeliverySubsidy(DeliveryRateCalculator.subsidy(offer.getCourierFee(), order.getDeliveryFee()));
            }
            orderRepository.save(order);
        }
        if (route != null) {
            route.setDeliveryPerson(courier);
            route.setStatus(RouteStatus.ASSIGNED);
            routeRepository.save(route);
        }
        return orders;
    }

    /** Preenche quem leva o pedido, o valor e o histórico (sem mexer na situação do entregador) */
    private void applyAssignment(Order order, DeliveryPerson courier, StaffCourier staff, LocalDateTime now) {
        if (staff != null) {
            order.setStaffCourier(staff);
            order.setDeliveryPerson(null);
            order.setCourierFee(staffFee(staff, order));
            order.setRestaurantDeliverySubsidy(BigDecimal.ZERO);
            orderService.addTracking(order, order.getStatus(), "Entregador definido: " + staff.getName(), now);
        } else {
            BigDecimal fee = courierFee(courier, order);
            order.setDeliveryPerson(courier);
            order.setStaffCourier(null);
            order.setCourierFee(fee);
            order.setRestaurantDeliverySubsidy(DeliveryRateCalculator.subsidy(fee, order.getDeliveryFee()));
            orderService.addTracking(order, order.getStatus(), "Entregador definido: " + courier.getUser().getFullName(), now);
        }
        order.setAssignedAt(now);
        order.setSearchingCourierSince(null);
    }

    /**
     * Tira o entregador do pedido (mesma regra de troca); o pedido volta ao despacho sem oferecer a ele de novo
     */
    @Transactional
    public void unassign(Long restaurantId, Long orderId) {
        Order order = lockRestaurantOrder(restaurantId, orderId);
        if (ReassignPolicy.kindOf(order) == null) {
            return;
        }
        LocalDateTime now = LocalDateTime.now(clock);
        assertCanReassign(order, now);
        String name = courierName(order);
        releaseCurrent(order, "A loja tirou o pedido de você");
        if (order.getRoute() != null) {
            leaveRoute(order);
        }
        order.setSoloDispatch(true);
        order.setSearchingCourierSince(null);
        // O cliente vê o histórico: mensagem neutra, sem detalhes da operação da loja
        orderService.addTracking(order, order.getStatus(), "Procurando outro entregador", now);
        log.info("Restaurante {} tirou o pedido {} de {}", restaurantId, orderId, name);
        orderRepository.save(order);
        events.publishEvent(new OrderChangedEvent(order.getId(), OrderChangedEvent.Type.ORDER_UPDATED));
    }

    private void assertCanReassign(Order order, LocalDateTime now) {
        Decision decision = ReassignPolicy.decide(order, now, properties.getLocationStaleSeconds());
        if (!decision.allowed()) {
            throw new BadRequestException(decision.reason());
        }
    }

    private static boolean isCurrent(Order order, AssignCourierRequest request) {
        return request.deliveryPersonId() != null
                ? order.getDeliveryPerson() != null && order.getDeliveryPerson().getId().equals(request.deliveryPersonId())
                : order.getStaffCourier() != null && order.getStaffCourier().getId().equals(request.staffCourierId());
    }

    /**
     * Tira quem está com o pedido: o entregador do app volta a ficar disponível, recebe o aviso e não recebe mais
     * oferta deste pedido
     */
    private void releaseCurrent(Order order, String reason) {
        if (order.getStaffCourier() != null) {
            order.setStaffCourier(null);
        }
        DeliveryPerson assigned = order.getDeliveryPerson();
        if (assigned != null) {
            DeliveryPerson courier = deliveryPersonRepository.findByIdForUpdate(assigned.getId()).orElseThrow();
            freeIfIdle(courier, order.getId());
            deliveryPersonRepository.save(courier);
            excludeFromOrder(order, courier);
            order.setDeliveryPerson(null);
            notifier.send(courier.getId(), new CourierMessage(CourierMessage.Type.ORDER_UNASSIGNED, null,
                    CourierOrderDTO.from(order), reason));
        }
        order.setCourierFee(null);
        order.setRestaurantDeliverySubsidy(null);
        order.setAssignedAt(null);
    }

    /** Registra uma oferta encerrada para o despacho automático não oferecer o pedido de novo a este entregador */
    private void excludeFromOrder(Order order, DeliveryPerson courier) {
        LocalDateTime now = LocalDateTime.now(clock);
        DeliveryOffer offer = new DeliveryOffer();
        offer.setOrder(order);
        offer.setDeliveryPerson(courier);
        offer.setStatus(DeliveryOfferStatus.CANCELLED);
        offer.setDeliveryDistanceKm(order.getDeliveryDistanceKm());
        offer.setCourierFee(order.getCourierFee() != null ? order.getCourierFee() : BigDecimal.ZERO);
        offer.setOfferedAt(now);
        offer.setExpiresAt(now);
        offer.setRespondedAt(now);
        offerRepository.save(offer);
    }

    private CourierOptionsDTO.Option appOption(CourierKind kind, DeliveryPerson courier, Order order) {
        Double pickupKm = pickupDistance(courier, order.getRestaurant());
        String blocked = blockedReason(courier, order);
        BigDecimal fee = courierFeeOrNull(courier, order);
        return new CourierOptionsDTO.Option(kind, courier.getId(), null, courier.getUser().getFullName(),
                courier.getPhotoUrl(), courier.getActiveVehicle() != null ? courier.getActiveVehicle().getType() : null,
                round(pickupKm), fee, blocked);
    }

    /** Motivo de o entregador do app não poder receber este pedido agora; nulo = pode */
    private String blockedReason(DeliveryPerson courier, Order order) {
        if (!courier.isActive()) {
            return "Entregador inativo";
        }
        if (courier.getWorkStatus() == CourierWorkStatus.BUSY) {
            return "Em outra entrega";
        }
        if (courier.getWorkStatus() != CourierWorkStatus.ONLINE) {
            return "Offline";
        }
        Organization organization = courier.getOrganization();
        if (organization == null || !organization.isOperational() || !organization.isDeliveryRateConfigured()) {
            return "A associação dele ainda não definiu a tabela de valores";
        }
        BigDecimal fee = DeliveryRateCalculator.courierFee(organization.getDeliveryRate(), order.getDeliveryDistanceKm());
        if (!CourierSelector.feeAllowed(fee, order.getDeliveryFee(), order.getRestaurant().isCoversDeliveryDifference())) {
            return "A tabela dele (" + money(fee) + ") passa da sua taxa de entrega";
        }
        return null;
    }

    private static BigDecimal courierFeeOrNull(DeliveryPerson courier, Order order) {
        Organization organization = courier.getOrganization();
        if (organization == null || !organization.isDeliveryRateConfigured()) {
            return null;
        }
        return DeliveryRateCalculator.courierFee(organization.getDeliveryRate(), order.getDeliveryDistanceKm());
    }

    private static BigDecimal courierFee(DeliveryPerson courier, Order order) {
        return DeliveryRateCalculator.courierFee(courier.getOrganization().getDeliveryRate(), order.getDeliveryDistanceKm());
    }

    /** Equipe própria recebe o valor combinado por entrega ou, sem ele, a taxa cobrada do cliente */
    static BigDecimal staffFee(StaffCourier staff, Order order) {
        if (staff.getFeePerDelivery() != null) {
            return staff.getFeePerDelivery();
        }
        return order.getDeliveryFee() != null ? order.getDeliveryFee() : BigDecimal.ZERO;
    }

    private static String courierName(Order order) {
        if (order.getStaffCourier() != null) {
            return order.getStaffCourier().getName();
        }
        return order.getDeliveryPerson() != null ? order.getDeliveryPerson().getUser().getFullName() : null;
    }

    private static String money(BigDecimal value) {
        return "R$ " + value.setScale(2, java.math.RoundingMode.HALF_UP).toPlainString().replace('.', ',');
    }

    private Order lockRestaurantOrder(Long restaurantId, Long orderId) {
        return orderRepository.findByIdForUpdate(orderId)
                .filter(o -> o.getRestaurant().getId().equals(restaurantId))
                .orElseThrow(() -> new ResourceNotFoundException("Pedido não encontrado"));
    }

    // ============= Núcleo =============

    /**
     * Oferece o pedido (já travado) ao melhor entregador disponível; sem ninguém, marca que está procurando
     */
    void dispatchLocked(Order order) {
        if (!DISPATCHABLE.contains(order.getStatus()) || order.getDeliveryPerson() != null
                || order.getStaffCourier() != null) {
            return;
        }
        // Com rotas ligadas, o planejador libera o pedido perto de ficar pronto (e junta com outros)
        if (order.getRestaurant().isRouteBatchingEnabled() && order.getDispatchReleasedAt() == null) {
            return;
        }
        if (order.getRoute() != null) {
            if (order.getRoute().getStatus() == RouteStatus.DISPATCHING) {
                dispatchRoute(order.getRoute());
            }
            return;
        }
        if (offerRepository.existsByOrderIdAndStatus(order.getId(), DeliveryOfferStatus.PENDING)) {
            return;
        }
        ensureDeliveryDistance(order);

        Optional<Choice> choice = chooseCourier(order, List.of(order));
        if (choice.isEmpty()) {
            if (order.getSearchingCourierSince() == null) {
                order.setSearchingCourierSince(LocalDateTime.now(clock));
                orderRepository.save(order);
                events.publishEvent(new OrderChangedEvent(order.getId(), OrderChangedEvent.Type.ORDER_UPDATED));
                log.info("Pedido {} sem entregador disponível; nova tentativa em instantes", order.getId());
            }
            return;
        }
        createOffer(order, choice.get().candidate(), choice.get().score(), null);
    }

    /**
     * Oferece a rota inteira a um entregador; a oferta fica registrada no pedido líder (primeiro da ordem)
     */
    void dispatchRoute(DeliveryRoute route) {
        List<Order> orders = waitingOrders(route);
        if (orders.isEmpty()) {
            return;
        }
        // Trava o líder: dois eventos de pedidos da mesma rota não criam duas ofertas
        Order lead = orderRepository.findByIdForUpdate(orders.get(0).getId()).orElseThrow();
        if (offerRepository.existsByOrderIdAndStatus(lead.getId(), DeliveryOfferStatus.PENDING)) {
            return;
        }
        orders.forEach(this::ensureDeliveryDistance);
        Optional<Choice> choice = chooseCourier(lead, orders);
        if (choice.isEmpty()) {
            LocalDateTime now = LocalDateTime.now(clock);
            for (Order order : orders) {
                if (order.getSearchingCourierSince() == null) {
                    order.setSearchingCourierSince(now);
                    orderRepository.save(order);
                    events.publishEvent(new OrderChangedEvent(order.getId(), OrderChangedEvent.Type.ORDER_UPDATED));
                }
            }
            return;
        }
        createOffer(lead, choice.get().candidate(), choice.get().score(), route);
    }

    /** Pedidos da rota que ainda esperam entregador, na ordem de entrega */
    private static List<Order> waitingOrders(DeliveryRoute route) {
        return route.sortedOrders().stream()
                .filter(o -> DISPATCHABLE.contains(o.getStatus()) && o.getDeliveryPerson() == null && o.getStaffCourier() == null)
                .toList();
    }

    private Optional<Choice> chooseCourier(Order order, List<Order> orders) {
        Restaurant restaurant = order.getRestaurant();
        LocalDateTime now = LocalDateTime.now(clock);
        Set<Long> excluded = new HashSet<>(offerRepository.findOfferedCourierIds(order.getId()));
        excluded.addAll(offerRepository.findCourierIdsWithPendingOffer());

        // 1) Fixos em check-in no restaurante
        List<Candidate> fixed = new ArrayList<>();
        for (CourierShift shift : shiftRepository.findOpenFixedAtRestaurant(restaurant.getId())) {
            DeliveryPerson courier = shift.getDeliveryPerson();
            if (courier.getWorkStatus() != CourierWorkStatus.ONLINE || excluded.contains(courier.getId())) {
                continue;
            }
            candidateFee(courier, orders).ifPresent(fee -> fixed.add(new Candidate(courier, null, fee, null,
                    shift.getDeliveriesCount(), shift.getLastDeliveryAt(), shift.getStartedAt())));
        }
        Optional<Choice> fixedChoice = CourierSelector.pickFixed(fixed);
        if (fixedChoice.isPresent()) {
            return fixedChoice;
        }

        CourierPolicy policy = restaurant.getCourierPolicy();
        if (policy == CourierPolicy.FIXED_ONLY && !restaurant.isFallbackToOpen()) {
            return Optional.empty();
        }

        // 2) Modo livre: perto do restaurante e, entre os próximos, quem ganhou menos hoje
        Set<Long> partnerIds = policy == CourierPolicy.PARTNERS_ONLY
                ? new HashSet<>(partnershipRepository.findActiveByRestaurant(restaurant.getId()).stream()
                .map(p -> p.getOrganization().getId()).toList())
                : null;
        LocalDateTime seenSince = now.minusSeconds(properties.getLocationStaleSeconds());
        List<Candidate> free = new ArrayList<>();
        for (DeliveryPerson courier : deliveryPersonRepository.findFreeOnlineCouriers(seenSince)) {
            if (excluded.contains(courier.getId())) {
                continue;
            }
            if (partnerIds != null && !partnerIds.contains(courier.getOrganization().getId())) {
                continue;
            }
            Double pickupKm = pickupDistance(courier, restaurant);
            if (pickupKm != null && pickupKm > properties.getSearchRadiusKm()) {
                continue;
            }
            candidateFee(courier, orders).ifPresent(fee -> free.add(
                    new Candidate(courier, pickupKm, fee, BigDecimal.ZERO, 0, null, null)));
        }
        if (free.isEmpty()) {
            return Optional.empty();
        }

        Map<Long, BigDecimal> earned = earnedToday(free.stream().map(c -> c.courier().getId()).toList());
        List<Candidate> withEarnings = free.stream()
                .map(c -> new Candidate(c.courier(), c.pickupDistanceKm(), c.courierFee(),
                        earned.getOrDefault(c.courier().getId(), BigDecimal.ZERO), 0, null, null))
                .toList();
        return CourierSelector.pickFree(withEarnings, properties.getSearchRadiusKm(),
                properties.getWeightDistance(), properties.getWeightFairness());
    }

    /**
     * Valor do entregador para este pedido, se ele puder recebê-lo (associação operante, tabela definida e
     * valor dentro da taxa ou coberto pelo restaurante)
     */
    private Optional<BigDecimal> candidateFee(DeliveryPerson courier, List<Order> orders) {
        Organization organization = courier.getOrganization();
        if (!courier.isActive() || organization == null || !organization.isOperational()
                || !organization.isDeliveryRateConfigured()) {
            return Optional.empty();
        }
        // Rota: o entregador recebe o valor CHEIO da tabela de cada pedido. Agrupar nunca reduz o ganho dele:
        // a rota serve para ele rodar menos (menos combustível) ganhando o mesmo que em viagens separadas.
        // Cada pedido também precisa caber na regra da taxa.
        BigDecimal total = BigDecimal.ZERO;
        for (Order order : orders) {
            BigDecimal fee = DeliveryRateCalculator.courierFee(organization.getDeliveryRate(), order.getDeliveryDistanceKm());
            if (!CourierSelector.feeAllowed(fee, order.getDeliveryFee(), order.getRestaurant().isCoversDeliveryDifference())) {
                return Optional.empty();
            }
            total = total.add(fee);
        }
        return Optional.of(total);
    }

    private void createOffer(Order order, Candidate candidate, double score, DeliveryRoute route) {
        // Trava o entregador para ele não receber duas ofertas ao mesmo tempo
        DeliveryPerson courier = deliveryPersonRepository.findByIdForUpdate(candidate.courier().getId()).orElseThrow();
        if (offerRepository.existsByDeliveryPersonIdAndStatus(courier.getId(), DeliveryOfferStatus.PENDING)) {
            return;
        }
        LocalDateTime now = LocalDateTime.now(clock);
        DeliveryOffer offer = new DeliveryOffer();
        offer.setOrder(order);
        offer.setRoute(route);
        offer.setDeliveryPerson(courier);
        offer.setPickupDistanceKm(round(candidate.pickupDistanceKm()));
        offer.setDeliveryDistanceKm(order.getDeliveryDistanceKm());
        offer.setCourierFee(candidate.courierFee());
        offer.setScore(score);
        offer.setOfferedAt(now);
        offer.setExpiresAt(now.plusSeconds(properties.getOfferTimeoutSeconds()));
        offerRepository.save(offer);

        notifier.send(courier.getId(), new CourierMessage(CourierMessage.Type.OFFER_CREATED,
                CourierOfferDTO.from(offer, now), null, null));
        log.info("Pedido {} oferecido ao entregador {} (R$ {}, pontuação {})", order.getId(), courier.getId(),
                candidate.courierFee(), String.format(Locale.ROOT, "%.3f", score));
    }

    /**
     * Fim da entrega para o entregador (entregue ou cancelada): libera para novas ofertas e atualiza os contadores.
     * Idempotente pelo {@code courierSettledAt}.
     */
    private void settleCourier(Order order, boolean delivered) {
        DeliveryPerson assigned = order.getDeliveryPerson();
        if (assigned == null || order.getCourierSettledAt() != null) {
            return;
        }
        LocalDateTime now = LocalDateTime.now(clock);
        DeliveryPerson courier = deliveryPersonRepository.findByIdForUpdate(assigned.getId()).orElseThrow();
        CourierShift shift = courier.getCurrentShift();

        if (delivered) {
            courier.setTotalDeliveries((courier.getTotalDeliveries() != null ? courier.getTotalDeliveries() : 0) + 1);
            if (shift != null && shift.isOpen()) {
                shift.setDeliveriesCount(shift.getDeliveriesCount() + 1);
                shift.setLastDeliveryAt(now);
                shiftRepository.save(shift);
            }
        }
        freeIfIdle(courier, order.getId());
        deliveryPersonRepository.save(courier);
        order.setCourierSettledAt(now);
        orderRepository.save(order);

        notifier.send(courier.getId(), new CourierMessage(
                delivered ? CourierMessage.Type.ORDER_UPDATED : CourierMessage.Type.ORDER_CANCELLED,
                null, CourierOrderDTO.from(order), delivered ? null : order.getCancellationReason()));
    }

    private void closePendingOffers(Order order, String reason) {
        for (DeliveryOffer offer : offerRepository.findByOrderIdAndStatus(order.getId(), DeliveryOfferStatus.PENDING)) {
            offer.setStatus(DeliveryOfferStatus.CANCELLED);
            offer.setRespondedAt(LocalDateTime.now(clock));
            offerRepository.save(offer);
            notifyClosed(offer, reason);
        }
    }

    /**
     * Recusa a oferta pendente do entregador (ao ficar offline) e manda o pedido para o próximo
     */
    public void declinePendingOffer(DeliveryPerson courier, String reason) {
        offerRepository.findPendingByCourier(courier.getId()).ifPresent(offer -> {
            offer.setStatus(DeliveryOfferStatus.DECLINED);
            offer.setRespondedAt(LocalDateTime.now(clock));
            offerRepository.save(offer);
            notifyClosed(offer, reason);
            events.publishEvent(new DispatchRequestedEvent(offer.getOrder().getId()));
        });
    }

    private void notifyClosed(DeliveryOffer offer, String reason) {
        CourierOfferDTO dto = CourierOfferDTO.builder().offerId(offer.getId()).orderId(offer.getOrder().getId()).build();
        notifier.send(offer.getDeliveryPerson().getId(),
                new CourierMessage(CourierMessage.Type.OFFER_CLOSED, dto, null, reason));
    }

    // ============= Rotas =============

    /**
     * Tira o pedido da rota e refaz a ordem dos que ficam; com um pedido só, a rota deixa de existir
     */
    public void leaveRoute(Order order) {
        DeliveryRoute route = order.getRoute();
        if (route == null) {
            return;
        }
        route.getOrders().remove(order);
        order.setRoute(null);
        order.setRouteSequence(null);
        orderRepository.save(order);

        List<Order> remaining = route.sortedOrders().stream()
                .filter(o -> o.getStatus() != OrderStatus.CANCELLED)
                .toList();
        boolean started = route.getDeliveryPerson() != null || route.getStaffCourier() != null;
        if (remaining.size() <= 1 && !started) {
            // Sem outro pedido para acompanhar, o que sobrou sai sozinho
            for (Order other : remaining) {
                other.setRoute(null);
                other.setRouteSequence(null);
                orderRepository.save(other);
            }
            route.getOrders().clear();
            route.setStatus(RouteStatus.CANCELLED);
        } else {
            for (int i = 0; i < remaining.size(); i++) {
                remaining.get(i).setRouteSequence(i + 1);
                orderRepository.save(remaining.get(i));
            }
            if (remaining.isEmpty()) {
                route.setStatus(RouteStatus.CANCELLED);
            }
        }
        routeRepository.save(route);
    }

    /**
     * Tira o pedido da rota por ação da loja (juntar em outra rota ou separar): encerra a oferta em andamento da
     * rota e do próprio pedido antes
     */
    public void pullFromRoute(Order order) {
        closePendingOffers(order, "A loja mudou a rota");
        DeliveryRoute route = order.getRoute();
        if (route == null) {
            return;
        }
        List<Order> waiting = waitingOrders(route);
        if (!waiting.isEmpty() && !waiting.get(0).getId().equals(order.getId())) {
            closePendingOffers(waiting.get(0), "A loja mudou a rota");
        }
        leaveRoute(order);
    }

    /** Retirada e entregas da rota: em andamento na primeira saída, concluída quando não sobra pedido aberto */
    private void updateRouteProgress(DeliveryRoute route) {
        if (route == null || route.getStatus() == RouteStatus.DONE || route.getStatus() == RouteStatus.CANCELLED) {
            return;
        }
        List<Order> orders = route.getOrders();
        boolean allClosed = orders.stream()
                .allMatch(o -> o.getStatus() == OrderStatus.DELIVERED || o.getStatus() == OrderStatus.CANCELLED);
        if (allClosed) {
            route.setStatus(RouteStatus.DONE);
            route.setCompletedAt(LocalDateTime.now(clock));
        } else if (orders.stream().anyMatch(o -> o.getPickedUpAt() != null || o.getStatus() == OrderStatus.OUT_FOR_DELIVERY)) {
            route.setStatus(RouteStatus.IN_PROGRESS);
        }
        routeRepository.save(route);
    }

    /**
     * Entregador ocupado volta a ficar disponível (ou offline, sem turno) quando não tem mais nenhuma entrega aberta
     * além de {@code finishedOrderId}
     */
    private void freeIfIdle(DeliveryPerson courier, Long finishedOrderId) {
        if (courier.getWorkStatus() != CourierWorkStatus.BUSY) {
            return;
        }
        boolean hasOther = orderRepository.findByCourierAndStatusIn(courier.getId(), ACTIVE_FOR_COURIER).stream()
                .anyMatch(o -> !o.getId().equals(finishedOrderId));
        if (hasOther) {
            return;
        }
        CourierShift shift = courier.getCurrentShift();
        boolean stillWorking = shift != null && shift.isOpen();
        courier.setWorkStatus(stillWorking ? CourierWorkStatus.ONLINE : CourierWorkStatus.OFFLINE);
        courier.setAvailable(stillWorking);
    }

    // ============= Auxiliares =============

    private void inNewTransaction(Long orderId, Consumer<Order> work) {
        try {
            newTransaction.executeWithoutResult(tx -> orderRepository.findByIdForUpdate(orderId).ifPresent(work));
        } catch (RuntimeException e) {
            log.error("Falha no despacho do pedido {}", orderId, e);
        }
    }

    private void ensureDeliveryDistance(Order order) {
        if (order.getDeliveryDistanceKm() != null) {
            return;
        }
        Restaurant restaurant = order.getRestaurant();
        if (restaurant.getLatitude() == null || restaurant.getLongitude() == null
                || order.getDeliveryLatitude() == null || order.getDeliveryLongitude() == null) {
            return;
        }
        order.setDeliveryDistanceKm(round(GeoUtils.haversineKm(restaurant.getLatitude().doubleValue(),
                restaurant.getLongitude().doubleValue(), order.getDeliveryLatitude(), order.getDeliveryLongitude())));
        orderRepository.save(order);
    }

    private static Double pickupDistance(DeliveryPerson courier, Restaurant restaurant) {
        if (restaurant.getLatitude() == null || restaurant.getLongitude() == null) {
            return null;
        }
        return GeoUtils.haversineKm(courier.getLastLatitude(), courier.getLastLongitude(),
                restaurant.getLatitude().doubleValue(), restaurant.getLongitude().doubleValue());
    }

    private Map<Long, BigDecimal> earnedToday(List<Long> courierIds) {
        LocalDate today = LocalDate.now(clock);
        Map<Long, BigDecimal> result = new HashMap<>();
        for (Object[] row : orderRepository.sumCourierFeesBetween(courierIds, today.atStartOfDay(),
                today.plusDays(1).atStartOfDay())) {
            result.put((Long) row[0], (BigDecimal) row[1]);
        }
        return result;
    }

    private static Double round(Double km) {
        return km == null ? null : Math.round(km * 100) / 100.0;
    }
}
