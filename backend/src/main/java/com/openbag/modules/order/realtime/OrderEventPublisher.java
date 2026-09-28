package com.openbag.modules.order.realtime;

import com.openbag.modules.order.dto.OrderDTO;
import com.openbag.modules.order.repository.OrderRepository;
import com.openbag.modules.order.service.CustomerOrderMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Envia os eventos de pedido pelo WebSocket somente depois do commit,
 * para que o cliente nunca receba um estado que acabou desfeito
 */
@Component
@Slf4j
public class OrderEventPublisher {

    /** Mensagem enviada nos tópicos */
    public record OrderMessage(OrderChangedEvent.Type type, OrderDTO order) {
    }

    /** Posição do entregador, só no tópico do cliente */
    public record LocationMessage(String type, OrderDTO.Location location) {
    }

    @Autowired
    private SimpMessagingTemplate messaging;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private CustomerOrderMapper customerOrderMapper;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    @Transactional(propagation = Propagation.REQUIRES_NEW, readOnly = true)
    public void onOrderChanged(OrderChangedEvent event) {
        orderRepository.findById(event.orderId()).ifPresent(order -> {
            messaging.convertAndSend("/topic/restaurants/" + order.getRestaurant().getId() + "/orders",
                    new OrderMessage(event.type(), OrderDTO.from(order)));
            // Tópico do cliente: sem dados internos da operação da loja
            messaging.convertAndSend("/topic/orders/" + order.getId(),
                    new OrderMessage(event.type(), customerOrderMapper.toDto(order)));
            log.debug("Evento {} do pedido {} enviado", event.type(), order.getId());
        });
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void onCourierLocation(CourierLocationEvent event) {
        messaging.convertAndSend("/topic/orders/" + event.orderId(), new LocationMessage("COURIER_LOCATION",
                new OrderDTO.Location(event.latitude(), event.longitude(), event.at())));
    }
}
