package com.openbag.order.core.service;

import net.javacrumbs.shedlock.spring.annotation.SchedulerLock;
import com.openbag.order.core.entity.CancelledBy;
import com.openbag.order.core.entity.OrderStatus;
import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.platform.web.exception.ResourceNotFoundException;
import com.openbag.order.core.dto.OrderDTO;
import com.openbag.order.core.entity.Order;
import com.openbag.order.realtime.OrderChangedEvent;
import com.openbag.order.core.repository.OrderRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;

/**
 * Operação dos pedidos pelo restaurante: quadro de pedidos ativos, histórico e avanço das etapas
 */
@Service
@Transactional
@Slf4j
public class RestaurantOrderService {

    /** Pedidos que aparecem no gestor e na cozinha */
    public static final Set<OrderStatus> ACTIVE = EnumSet.of(OrderStatus.PENDING, OrderStatus.CONFIRMED,
            OrderStatus.PREPARING, OrderStatus.READY_FOR_PICKUP, OrderStatus.OUT_FOR_DELIVERY);

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private OrderService orderService;

    @Autowired
    private ApplicationEventPublisher events;

    @Autowired
    private Clock clock;

    @Autowired
    private TransactionTemplate transactionTemplate;

    @Transactional(readOnly = true)
    public List<OrderDTO> getBoard(Long restaurantId) {
        return orderRepository.findByRestaurantIdAndStatusInOrderByOrderDateAsc(restaurantId, ACTIVE).stream()
                .map(OrderDTO::from)
                .toList();
    }

    /**
     * Histórico de um dia (padrão: hoje), opcionalmente filtrado por status
     */
    @Transactional(readOnly = true)
    public Page<OrderDTO> getHistory(Long restaurantId, LocalDate date, OrderStatus status, Pageable pageable) {
        LocalDate day = date != null ? date : LocalDate.now(clock);
        LocalDateTime start = day.atStartOfDay();
        LocalDateTime end = day.plusDays(1).atStartOfDay();
        Page<Order> page = status != null
                ? orderRepository.findByRestaurantIdAndStatusAndOrderDateBetweenOrderByOrderDateDesc(restaurantId, status, start, end, pageable)
                : orderRepository.findByRestaurantIdAndOrderDateBetweenOrderByOrderDateDesc(restaurantId, start, end, pageable);
        return page.map(OrderDTO::from);
    }

    // ============= Etapas =============

    public OrderDTO accept(Long restaurantId, Long orderId) {
        return transition(restaurantId, orderId, EnumSet.of(OrderStatus.PENDING), OrderStatus.CONFIRMED,
                "Pedido confirmado pelo restaurante", (order, now) -> {
                    order.setAcceptedAt(now);
                    order.setExpectedReadyAt(now.plusMinutes(order.getRestaurant().getDefaultPreparationMinutes()));
                });
    }

    public OrderDTO start(Long restaurantId, Long orderId) {
        return transition(restaurantId, orderId, EnumSet.of(OrderStatus.CONFIRMED), OrderStatus.PREPARING,
                "Pedido em preparo", (order, now) -> {
                });
    }

    /** A cozinha pode marcar como pronto direto do "a fazer" (itens que não precisam de preparo) */
    public OrderDTO ready(Long restaurantId, Long orderId) {
        return transition(restaurantId, orderId, EnumSet.of(OrderStatus.CONFIRMED, OrderStatus.PREPARING),
                OrderStatus.READY_FOR_PICKUP, "Pedido pronto", (order, now) -> order.setReadyAt(now));
    }

    public OrderDTO dispatch(Long restaurantId, Long orderId) {
        Order order = findOrder(restaurantId, orderId);
        if (order.isPickup()) {
            throw new BadRequestException("Este pedido é para retirada na loja");
        }
        return OrderDTO.from(advance(order, EnumSet.of(OrderStatus.READY_FOR_PICKUP), OrderStatus.OUT_FOR_DELIVERY,
                "Pedido saiu para entrega", (o, now) -> {
                    o.setDispatchedAt(now);
                    // Equipe própria: a loja marca a saída no lugar do entregador
                    if (o.getStaffCourier() != null) {
                        o.setPickedUpAt(now);
                    }
                }));
    }

    /**
     * Entregue: o pagamento (na entrega) é considerado recebido. Na retirada, o cliente busca o pedido pronto
     * direto no balcão.
     */
    public OrderDTO deliver(Long restaurantId, Long orderId) {
        Order order = findOrder(restaurantId, orderId);
        boolean pickup = order.isPickup();
        return OrderDTO.from(advance(order,
                EnumSet.of(pickup ? OrderStatus.READY_FOR_PICKUP : OrderStatus.OUT_FOR_DELIVERY), OrderStatus.DELIVERED,
                pickup ? "Pedido retirado pelo cliente" : "Pedido entregue", (o, now) -> {
                    o.setDeliveredAt(now);
                    o.setPaymentStatus(Order.PaymentStatus.PAID);
                }));
    }

    /**
     * Recusa um pedido novo ou cancela um pedido já aceito que ainda não ficou pronto
     */
    public OrderDTO reject(Long restaurantId, Long orderId, String reason) {
        if (reason == null || reason.isBlank()) {
            throw new BadRequestException("Informe o motivo para o cliente");
        }
        String message = "Cancelado pelo restaurante: " + reason.trim();
        return transition(restaurantId, orderId, EnumSet.of(OrderStatus.PENDING, OrderStatus.CONFIRMED, OrderStatus.PREPARING),
                OrderStatus.CANCELLED, message, (order, now) -> {
                    order.setCancelledAt(now);
                    order.setCancelledBy(CancelledBy.RESTAURANT);
                    order.setCancellationReason(reason.trim());
                });
    }

    /**
     * Cancela os pedidos que o restaurante (modo MANUAL) não aceitou dentro do prazo
     */
    @Scheduled(fixedDelayString = "${app.orders.expiration-check-ms:30000}",
            initialDelayString = "${app.orders.expiration-initial-delay-ms:30000}")
    @Transactional(propagation = Propagation.NOT_SUPPORTED)
    @SchedulerLock(name = "orders.expireUnanswered", lockAtMostFor = "PT5M", lockAtLeastFor = "PT10S")
    public void expireUnansweredOrders() {
        LocalDateTime now = LocalDateTime.now(clock);
        for (Long orderId : orderRepository.findIdsByStatusAndAcceptDeadlineBefore(OrderStatus.PENDING, now)) {
            // Um pedido por transação, travado: o aceite da loja no mesmo instante espera e depois vê o cancelamento
            try {
                transactionTemplate.executeWithoutResult(tx -> expireIfUnanswered(orderId, now));
            } catch (RuntimeException e) {
                log.error("Falha ao expirar o pedido {}", orderId, e);
            }
        }
    }

    private void expireIfUnanswered(Long orderId, LocalDateTime now) {
        Order order = orderRepository.findByIdForUpdate(orderId).orElse(null);
        if (order == null || order.getStatus() != OrderStatus.PENDING || order.getAcceptDeadline() == null
                || !order.getAcceptDeadline().isBefore(now)) {
            return;
        }
        order.setStatus(OrderStatus.CANCELLED);
        order.setCancelledAt(now);
        order.setCancelledBy(CancelledBy.SYSTEM);
        order.setCancellationReason("O restaurante não respondeu a tempo");
        orderService.addTracking(order, OrderStatus.CANCELLED, "Cancelado automaticamente: o restaurante não respondeu a tempo", now);
        orderRepository.save(order);
        events.publishEvent(new OrderChangedEvent(order.getId(), OrderChangedEvent.Type.ORDER_UPDATED));
        log.info("Pedido {} cancelado por falta de resposta do restaurante {}", order.getId(), order.getRestaurant().getId());
    }

    // ============= Helpers =============

    @FunctionalInterface
    public interface StepEffect {
        void apply(Order order, LocalDateTime now);
    }

    private OrderDTO transition(Long restaurantId, Long orderId, Set<OrderStatus> allowedFrom, OrderStatus target,
                                String message, StepEffect effect) {
        return OrderDTO.from(advance(findOrder(restaurantId, orderId), allowedFrom, target, message, effect));
    }

    /**
     * Pedido do restaurante, travado: cada etapa lê e grava o pedido sem que o entregador, o cliente ou outra aba
     * do painel mudem ele no meio (antes, marcar "pronto" durante o aceite apagava o entregador)
     */
    private Order findOrder(Long restaurantId, Long orderId) {
        return orderRepository.findByIdForUpdate(orderId)
                .filter(o -> o.getRestaurant().getId().equals(restaurantId))
                .orElseThrow(() -> new ResourceNotFoundException("Pedido não encontrado"));
    }

    /**
     * Avança o pedido de etapa: valida a origem, aplica o efeito, registra no histórico e avisa em tempo real.
     * Usado também pelo entregador (retirada e entrega).
     */
    public Order advance(Order order, Set<OrderStatus> allowedFrom, OrderStatus target, String message,
                         StepEffect effect) {
        if (!allowedFrom.contains(order.getStatus()) || !order.getStatus().canTransitionTo(target)) {
            throw new BadRequestException(order.getStatus() == OrderStatus.CANCELLED
                    ? "Este pedido já foi cancelado"
                    : "Não é possível mudar o pedido de \"" + order.getStatus().getDisplayName() + "\" para \""
                    + target.getDisplayName() + "\"");
        }

        LocalDateTime now = LocalDateTime.now(clock);
        order.setStatus(target);
        effect.apply(order, now);
        orderService.addTracking(order, target, message, now);
        Order saved = orderRepository.save(order);
        events.publishEvent(new OrderChangedEvent(saved.getId(), OrderChangedEvent.Type.ORDER_UPDATED));
        return saved;
    }
}
