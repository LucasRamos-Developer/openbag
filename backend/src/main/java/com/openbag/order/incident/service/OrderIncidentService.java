package com.openbag.order.incident.service;

import com.openbag.delivery.courier.entity.DeliveryPerson;
import com.openbag.order.core.entity.Order;
import com.openbag.order.incident.entity.IncidentType;
import com.openbag.order.incident.entity.OrderIncident;
import com.openbag.order.incident.repository.OrderIncidentRepository;
import com.openbag.order.realtime.OrderChangedEvent;
import com.openbag.platform.web.exception.BadRequestException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDateTime;

/**
 * Registra as ocorrências do pedido. Quem chama já validou que o pedido é do entregador e o travou.
 * A loja recebe o pedido atualizado pelo WebSocket; o cliente não vê as ocorrências.
 */
@Service
@Slf4j
public class OrderIncidentService {

    @Autowired
    private OrderIncidentRepository incidentRepository;

    @Autowired
    private ApplicationEventPublisher events;

    @Autowired
    private Clock clock;

    /**
     * Registra a ocorrência. O mesmo tipo relatado de novo pelo mesmo entregador no mesmo pedido (dois toques)
     * não cria outra, a não ser em "outro", que traz uma observação diferente a cada vez.
     */
    @Transactional(propagation = Propagation.MANDATORY)
    public void report(Order order, DeliveryPerson courier, IncidentType type, String note) {
        String text = note == null || note.isBlank() ? null : note.trim();
        if (type == IncidentType.OTHER && text == null) {
            throw new BadRequestException("Conte em poucas palavras o que aconteceu");
        }
        if (type != IncidentType.OTHER
                && incidentRepository.existsByOrderIdAndDeliveryPersonIdAndType(order.getId(), courier.getId(), type)) {
            return;
        }

        OrderIncident incident = new OrderIncident();
        incident.setOrder(order);
        incident.setRestaurant(order.getRestaurant());
        // A associação registrada no pedido e, sem ela, a do entregador (como no Caixa)
        incident.setOrganization(order.getCourierOrganization() != null
                ? order.getCourierOrganization() : courier.getOrganization());
        incident.setDeliveryPerson(courier);
        incident.setType(type);
        incident.setNote(text);
        incident.setCreatedAt(LocalDateTime.now(clock));
        incidentRepository.save(incident);
        order.getIncidents().add(incident);

        events.publishEvent(new OrderChangedEvent(order.getId(), OrderChangedEvent.Type.ORDER_UPDATED));
        log.info("Ocorrência {} no pedido {} (entregador {})", type, order.getId(), courier.getId());
    }
}
