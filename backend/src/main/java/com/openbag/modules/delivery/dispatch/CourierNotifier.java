package com.openbag.modules.delivery.dispatch;

import com.openbag.modules.delivery.dto.CourierMessage;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

/**
 * Envia mensagens ao tópico do entregador (/topic/couriers/{id}). Dentro de uma transação, só depois do commit.
 */
@Component
@Slf4j
public class CourierNotifier {

    public static String topic(Long deliveryPersonId) {
        return "/topic/couriers/" + deliveryPersonId;
    }

    @Autowired
    private SimpMessagingTemplate messaging;

    public void send(Long deliveryPersonId, CourierMessage message) {
        Runnable task = () -> {
            messaging.convertAndSend(topic(deliveryPersonId), message);
            log.debug("Mensagem {} enviada ao entregador {}", message.type(), deliveryPersonId);
        };
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    task.run();
                }
            });
        } else {
            task.run();
        }
    }
}
