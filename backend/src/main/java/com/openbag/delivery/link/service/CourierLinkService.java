package com.openbag.delivery.link.service;

import com.openbag.delivery.link.entity.CourierLinkStatus;
import com.openbag.delivery.link.entity.LinkRequester;
import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.platform.web.exception.ResourceNotFoundException;
import com.openbag.delivery.link.dto.CourierLinkDTO;
import com.openbag.delivery.courier.entity.DeliveryPerson;
import com.openbag.delivery.link.entity.RestaurantCourierLink;
import com.openbag.delivery.courier.repository.DeliveryPersonRepository;
import com.openbag.delivery.link.repository.RestaurantCourierLinkRepository;
import com.openbag.restaurant.store.entity.Restaurant;
import com.openbag.restaurant.store.repository.RestaurantRepository;
import com.openbag.account.entity.User;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;
import com.openbag.delivery.courier.service.CourierWorkService;

/**
 * Vínculos de entregador fixo. Quem pede é uma parte e quem aceita é a outra:
 * o entregador pede e o dono aprova, ou o dono convida e o entregador aceita. Qualquer lado encerra.
 */
@Service
@Transactional
@Slf4j
public class CourierLinkService {

    private static final Set<CourierLinkStatus> VISIBLE = EnumSet.of(CourierLinkStatus.PENDING, CourierLinkStatus.ACTIVE);

    @Autowired
    private RestaurantCourierLinkRepository linkRepository;

    @Autowired
    private RestaurantRepository restaurantRepository;

    @Autowired
    private DeliveryPersonRepository deliveryPersonRepository;

    // Lazy: o serviço de trabalho também consulta os vínculos
    @Lazy
    @Autowired
    private CourierWorkService workService;

    // ============= Restaurante =============

    @Transactional(readOnly = true)
    public List<CourierLinkDTO> listForRestaurant(Long restaurantId) {
        return linkRepository.findByRestaurant(restaurantId, VISIBLE).stream()
                .map(link -> CourierLinkDTO.from(link, workService.isCheckedInAt(link.getDeliveryPerson(), restaurantId)))
                .toList();
    }

    public CourierLinkDTO inviteCourier(Long restaurantId, String courierSlug) {
        Restaurant restaurant = restaurantRepository.findById(restaurantId)
                .orElseThrow(() -> new ResourceNotFoundException("Restaurante não encontrado"));
        DeliveryPerson courier = deliveryPersonRepository.findBySlug(courierSlug)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Entregador não encontrado. Use o link do perfil público dele (o do QR code da placa)."));
        return CourierLinkDTO.from(open(restaurant, courier, LinkRequester.RESTAURANT), false);
    }

    public CourierLinkDTO approve(Long restaurantId, Long linkId) {
        RestaurantCourierLink link = findForRestaurant(restaurantId, linkId);
        requirePendingFrom(link, LinkRequester.COURIER, "Este vínculo não está aguardando a sua aprovação");
        return decide(link, CourierLinkStatus.ACTIVE);
    }

    public CourierLinkDTO reject(Long restaurantId, Long linkId) {
        RestaurantCourierLink link = findForRestaurant(restaurantId, linkId);
        requirePendingFrom(link, LinkRequester.COURIER, "Este vínculo não está aguardando a sua aprovação");
        return decide(link, CourierLinkStatus.REJECTED);
    }

    public CourierLinkDTO endByRestaurant(Long restaurantId, Long linkId) {
        return end(findForRestaurant(restaurantId, linkId));
    }

    // ============= Entregador =============

    @Transactional(readOnly = true)
    public List<CourierLinkDTO> listMine(User user) {
        DeliveryPerson courier = findCourier(user);
        return linkRepository.findByCourier(courier.getId(), VISIBLE).stream()
                .map(link -> CourierLinkDTO.from(link, workService.isCheckedInAt(courier, link.getRestaurant().getId())))
                .toList();
    }

    public CourierLinkDTO request(User user, String restaurantSlug) {
        DeliveryPerson courier = findCourier(user);
        Restaurant restaurant = restaurantRepository.findBySlugAndIsActiveTrue(restaurantSlug)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Restaurante não encontrado. Cole o link da página do restaurante (/r/...)."));
        return CourierLinkDTO.from(open(restaurant, courier, LinkRequester.COURIER), false);
    }

    public CourierLinkDTO accept(User user, Long linkId) {
        RestaurantCourierLink link = findForCourier(user, linkId);
        requirePendingFrom(link, LinkRequester.RESTAURANT, "Este convite não está aguardando a sua resposta");
        return decide(link, CourierLinkStatus.ACTIVE);
    }

    public CourierLinkDTO decline(User user, Long linkId) {
        RestaurantCourierLink link = findForCourier(user, linkId);
        requirePendingFrom(link, LinkRequester.RESTAURANT, "Este convite não está aguardando a sua resposta");
        return decide(link, CourierLinkStatus.REJECTED);
    }

    public CourierLinkDTO endByCourier(User user, Long linkId) {
        return end(findForCourier(user, linkId));
    }

    /**
     * O entregador é fixo (vínculo ACTIVE) deste restaurante
     */
    @Transactional(readOnly = true)
    public boolean isFixedCourier(Long restaurantId, Long deliveryPersonId) {
        return linkRepository.existsByRestaurantIdAndDeliveryPersonIdAndStatus(
                restaurantId, deliveryPersonId, CourierLinkStatus.ACTIVE);
    }

    // ============= Núcleo =============

    private RestaurantCourierLink open(Restaurant restaurant, DeliveryPerson courier, LinkRequester requestedBy) {
        linkRepository.findOpen(restaurant.getId(), courier.getId(), CourierLinkStatus.OPEN).ifPresent(existing -> {
            throw new BadRequestException(existing.getStatus() == CourierLinkStatus.ACTIVE
                    ? "Este entregador já é fixo deste restaurante"
                    : "Já existe um pedido de vínculo aguardando resposta");
        });
        RestaurantCourierLink link = new RestaurantCourierLink();
        link.setRestaurant(restaurant);
        link.setDeliveryPerson(courier);
        link.setRequestedBy(requestedBy);
        link.setStatus(CourierLinkStatus.PENDING);
        log.info("Vínculo fixo pedido por {}: restaurante {} / entregador {}", requestedBy, restaurant.getId(), courier.getId());
        return linkRepository.save(link);
    }

    private CourierLinkDTO decide(RestaurantCourierLink link, CourierLinkStatus status) {
        link.setStatus(status);
        link.setDecidedAt(LocalDateTime.now());
        if (status == CourierLinkStatus.REJECTED) {
            link.setEndedAt(LocalDateTime.now());
        }
        return CourierLinkDTO.from(linkRepository.save(link), false);
    }

    private CourierLinkDTO end(RestaurantCourierLink link) {
        if (!CourierLinkStatus.OPEN.contains(link.getStatus())) {
            throw new BadRequestException("Este vínculo já foi encerrado");
        }
        // Encerrar o vínculo encerra o check-in no restaurante
        workService.endFixedShiftAt(link.getDeliveryPerson(), link.getRestaurant().getId());
        link.setStatus(CourierLinkStatus.ENDED);
        link.setEndedAt(LocalDateTime.now());
        return CourierLinkDTO.from(linkRepository.save(link), false);
    }

    private static void requirePendingFrom(RestaurantCourierLink link, LinkRequester requestedBy, String message) {
        if (link.getStatus() != CourierLinkStatus.PENDING || link.getRequestedBy() != requestedBy) {
            throw new BadRequestException(message);
        }
    }

    private RestaurantCourierLink findForRestaurant(Long restaurantId, Long linkId) {
        return linkRepository.findByIdAndRestaurantId(linkId, restaurantId)
                .orElseThrow(() -> new ResourceNotFoundException("Vínculo não encontrado"));
    }

    private RestaurantCourierLink findForCourier(User user, Long linkId) {
        return linkRepository.findByIdAndDeliveryPersonId(linkId, findCourier(user).getId())
                .orElseThrow(() -> new ResourceNotFoundException("Vínculo não encontrado"));
    }

    private DeliveryPerson findCourier(User user) {
        return deliveryPersonRepository.findByUserId(user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Perfil de entregador não encontrado"));
    }
}
