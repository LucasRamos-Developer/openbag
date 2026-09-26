package com.openbag.modules.order.realtime;

import com.openbag.modules.order.dto.OrderDTO;
import com.openbag.modules.order.repository.OrderRepository;
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

    @Autowired
    private SimpMessagingTemplate messaging;

    @Autowired
    private OrderRepository orderRepository;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    @Transactional(propagation = Propagation.REQUIRES_NEW, readOnly = true)
    public void onOrderChanged(OrderChangedEvent event) {
        orderRepository.findById(event.orderId()).ifPresent(order -> {
            OrderMessage message = new OrderMessage(event.type(), OrderDTO.from(order));
            messaging.convertAndSend("/topic/restaurants/" + order.getRestaurant().getId() + "/orders", message);
            messaging.convertAndSend("/topic/orders/" + order.getId(), message);
            log.debug("Evento {} do pedido {} enviado", event.type(), order.getId());
        });
    }
}
