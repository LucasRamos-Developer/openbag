package com.openbag.modules.delivery.dispatch;

import com.openbag.enums.CourierPolicy;
import com.openbag.enums.CourierWorkStatus;
import com.openbag.enums.DeliveryOfferStatus;
import com.openbag.enums.OrderStatus;
import com.openbag.exception.BadRequestException;
import com.openbag.exception.ResourceNotFoundException;
import com.openbag.modules.delivery.dispatch.CourierSelector.Candidate;
import com.openbag.modules.delivery.dispatch.CourierSelector.Choice;
import com.openbag.modules.delivery.dto.CourierMessage;
import com.openbag.modules.delivery.dto.CourierOfferDTO;
import com.openbag.modules.delivery.dto.CourierOrderDTO;
import com.openbag.modules.delivery.entity.CourierShift;
import com.openbag.modules.delivery.entity.DeliveryOffer;
import com.openbag.modules.delivery.entity.DeliveryPerson;
import com.openbag.modules.delivery.repository.CourierShiftRepository;
import com.openbag.modules.delivery.repository.DeliveryOfferRepository;
import com.openbag.modules.delivery.repository.DeliveryPersonRepository;
import com.openbag.modules.delivery.repository.RestaurantPartnershipRepository;
import com.openbag.modules.delivery.service.DeliveryRateCalculator;
import com.openbag.modules.order.entity.Order;
import com.openbag.modules.order.realtime.OrderChangedEvent;
import com.openbag.modules.order.repository.OrderRepository;
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
            return;
        }
        if (status == OrderStatus.DELIVERED) {
            closePendingOffers(order, "O pedido já foi entregue");
            settleCourier(order, true);
            return;
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
        if (order.getDeliveryPerson() == null) {
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

    /**
     * O restaurante escolhe um dos fixos em check-in para o pedido (a oferta vai direto para ele)
     */
    @Transactional
    public void offerToFixedCourier(Long restaurantId, Long orderId, Long deliveryPersonId) {
        Order order = orderRepository.findByIdForUpdate(orderId)
                .filter(o -> o.getRestaurant().getId().equals(restaurantId))
                .orElseThrow(() -> new ResourceNotFoundException("Pedido não encontrado"));
        if (!DISPATCHABLE.contains(order.getStatus()) || order.getDeliveryPerson() != null) {
            throw new BadRequestException("Este pedido não está aguardando entregador");
        }
        CourierShift shift = shiftRepository.findOpenFixedAtRestaurant(restaurantId).stream()
                .filter(s -> s.getDeliveryPerson().getId().equals(deliveryPersonId))
                .findFirst()
                .orElseThrow(() -> new BadRequestException("Este entregador não está em check-in no restaurante"));
        DeliveryPerson courier = deliveryPersonRepository.findByIdForUpdate(deliveryPersonId).orElseThrow();
        if (courier.getWorkStatus() != CourierWorkStatus.ONLINE
                || offerRepository.existsByDeliveryPersonIdAndStatus(deliveryPersonId, DeliveryOfferStatus.PENDING)) {
            throw new BadRequestException("Este entregador está ocupado agora");
        }
        closePendingOffers(order, "O restaurante escolheu outro entregador");
        ensureDeliveryDistance(order);
        Organization organization = courier.getOrganization();
        if (organization == null || !organization.isDeliveryRateConfigured()) {
            throw new BadRequestException("A associação do entregador ainda não definiu a tabela de valores");
        }
        BigDecimal fee = DeliveryRateCalculator.courierFee(organization.getDeliveryRate(), order.getDeliveryDistanceKm());
        createOffer(order, new Candidate(courier, null, fee, BigDecimal.ZERO, shift.getDeliveriesCount(),
                shift.getLastDeliveryAt(), shift.getStartedAt()), 0);
    }

    // ============= Núcleo =============

    /**
     * Oferece o pedido (já travado) ao melhor entregador disponível; sem ninguém, marca que está procurando
     */
    void dispatchLocked(Order order) {
        if (!DISPATCHABLE.contains(order.getStatus()) || order.getDeliveryPerson() != null
                || offerRepository.existsByOrderIdAndStatus(order.getId(), DeliveryOfferStatus.PENDING)) {
            return;
        }
        ensureDeliveryDistance(order);

        Optional<Choice> choice = chooseCourier(order);
        if (choice.isEmpty()) {
            if (order.getSearchingCourierSince() == null) {
                order.setSearchingCourierSince(LocalDateTime.now(clock));
                orderRepository.save(order);
                events.publishEvent(new OrderChangedEvent(order.getId(), OrderChangedEvent.Type.ORDER_UPDATED));
                log.info("Pedido {} sem entregador disponível; nova tentativa em instantes", order.getId());
            }
            return;
        }
        createOffer(order, choice.get().candidate(), choice.get().score());
    }

    private Optional<Choice> chooseCourier(Order order) {
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
            candidateFee(courier, order).ifPresent(fee -> fixed.add(new Candidate(courier, null, fee, null,
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
            candidateFee(courier, order).ifPresent(fee -> free.add(
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
    private Optional<BigDecimal> candidateFee(DeliveryPerson courier, Order order) {
        Organization organization = courier.getOrganization();
        if (!courier.isActive() || organization == null || !organization.isOperational()
                || !organization.isDeliveryRateConfigured()) {
            return Optional.empty();
        }
        BigDecimal fee = DeliveryRateCalculator.courierFee(organization.getDeliveryRate(), order.getDeliveryDistanceKm());
        return CourierSelector.feeAllowed(fee, order.getDeliveryFee(), order.getRestaurant().isCoversDeliveryDifference())
                ? Optional.of(fee)
                : Optional.empty();
    }

    private void createOffer(Order order, Candidate candidate, double score) {
        // Trava o entregador para ele não receber duas ofertas ao mesmo tempo
        DeliveryPerson courier = deliveryPersonRepository.findByIdForUpdate(candidate.courier().getId()).orElseThrow();
        if (offerRepository.existsByDeliveryPersonIdAndStatus(courier.getId(), DeliveryOfferStatus.PENDING)) {
            return;
        }
        LocalDateTime now = LocalDateTime.now(clock);
        DeliveryOffer offer = new DeliveryOffer();
        offer.setOrder(order);
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
        if (courier.getWorkStatus() == CourierWorkStatus.BUSY) {
            boolean stillWorking = shift != null && shift.isOpen();
            courier.setWorkStatus(stillWorking ? CourierWorkStatus.ONLINE : CourierWorkStatus.OFFLINE);
            courier.setAvailable(stillWorking);
        }
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
