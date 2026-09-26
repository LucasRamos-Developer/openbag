package com.openbag.modules.restaurant.service;

import com.openbag.exception.BadRequestException;
import com.openbag.exception.ResourceNotFoundException;
import com.openbag.modules.restaurant.dto.*;
import com.openbag.modules.restaurant.entity.OpeningHour;
import com.openbag.modules.restaurant.entity.Restaurant;
import com.openbag.modules.restaurant.repository.RestaurantRepository;
import com.openbag.modules.user.entity.User;
import com.openbag.modules.delivery.service.RestaurantDeliveryService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;

/**
 * Operação da loja pelo dono: horários, pausa, abrir/fechar e configurações de pedido
 */
@Service
@Transactional
@Slf4j
public class StoreService {

    @Autowired
    private RestaurantDeliveryService restaurantDeliveryService;

    @Autowired
    private RestaurantRepository restaurantRepository;

    @Autowired
    private Clock clock;

    @Transactional(readOnly = true)
    public List<RestaurantSummaryDTO> getMyRestaurants(User owner) {
        LocalDateTime now = LocalDateTime.now(clock);
        return restaurantRepository.findByOwnerIdOrderByNameAsc(owner.getId()).stream()
                .map(r -> new RestaurantSummaryDTO(r.getId(), r.getName(), r.getSlug(), r.getLogoUrl(),
                        r.isActive(), r.isOpenNow(now)))
                .toList();
    }

    @Transactional(readOnly = true)
    public StoreDTO getStore(Long restaurantId) {
        return toDTO(findRestaurant(restaurantId));
    }

    public StoreDTO updateSettings(Long restaurantId, StoreSettingsRequest request) {
        if (request.getDeliveryTimeMin() > request.getDeliveryTimeMax()) {
            throw new BadRequestException("O tempo mínimo de entrega não pode ser maior que o máximo");
        }
        Restaurant restaurant = findRestaurant(restaurantId);
        restaurantDeliveryService.assertDeliveryFeeCovered(restaurant, request.getDeliveryFee());
        restaurant.setAcceptanceMode(request.getAcceptanceMode());
        restaurant.setAcceptanceTimeoutMinutes(request.getAcceptanceTimeoutMinutes());
        restaurant.setDefaultPreparationMinutes(request.getDefaultPreparationMinutes());
        restaurant.setDeliveryFee(request.getDeliveryFee());
        restaurant.setMinimumOrder(request.getMinimumOrder());
        restaurant.setDeliveryTimeMin(request.getDeliveryTimeMin());
        restaurant.setDeliveryTimeMax(request.getDeliveryTimeMax());
        restaurant.setPriceRange(request.getPriceRange() == null || request.getPriceRange().isBlank()
                ? null : request.getPriceRange());
        restaurant.setAutoPrintTicket(request.isAutoPrintTicket());
        return toDTO(restaurantRepository.save(restaurant));
    }

    public StoreDTO replaceOpeningHours(Long restaurantId, List<OpeningHourDTO> hours) {
        for (OpeningHourDTO hour : hours) {
            if (hour.getOpenTime().equals(hour.getCloseTime())) {
                throw new BadRequestException("Abertura e fechamento não podem ser iguais (dia " + hour.getWeekday() + ")");
            }
        }
        Restaurant restaurant = findRestaurant(restaurantId);

        // Mantém a mesma lista para o orphanRemoval apagar os horários antigos
        restaurant.getOpeningHours().clear();
        for (OpeningHourDTO dto : hours) {
            OpeningHour hour = new OpeningHour();
            hour.setRestaurant(restaurant);
            hour.setWeekday(dto.getWeekday());
            hour.setOpenTime(dto.getOpenTime());
            hour.setCloseTime(dto.getCloseTime());
            hour.setLabel(dto.getLabel());
            hour.setObservation(dto.getObservation());
            restaurant.getOpeningHours().add(hour);
        }
        return toDTO(restaurantRepository.save(restaurant));
    }

    public StoreDTO pause(Long restaurantId, int minutes) {
        Restaurant restaurant = findRestaurant(restaurantId);
        restaurant.setPausedUntil(LocalDateTime.now(clock).plusMinutes(minutes));
        log.info("Restaurante {} pausado por {} minutos", restaurantId, minutes);
        return toDTO(restaurantRepository.save(restaurant));
    }

    public StoreDTO resume(Long restaurantId) {
        Restaurant restaurant = findRestaurant(restaurantId);
        restaurant.setPausedUntil(null);
        return toDTO(restaurantRepository.save(restaurant));
    }

    public StoreDTO setOpen(Long restaurantId, boolean open) {
        Restaurant restaurant = findRestaurant(restaurantId);
        restaurant.setOpen(open);
        if (open) {
            restaurant.setPausedUntil(null);
        }
        return toDTO(restaurantRepository.save(restaurant));
    }

    private Restaurant findRestaurant(Long restaurantId) {
        return restaurantRepository.findById(restaurantId)
                .orElseThrow(() -> new ResourceNotFoundException("Restaurante não encontrado"));
    }

    private StoreDTO toDTO(Restaurant restaurant) {
        LocalDateTime now = LocalDateTime.now(clock);
        return StoreDTO.builder()
                .id(restaurant.getId())
                .name(restaurant.getName())
                .slug(restaurant.getSlug())
                .logoUrl(restaurant.getLogoUrl())
                .bannerUrl(restaurant.getBannerUrl())
                .active(restaurant.isActive())
                .open(restaurant.isOpen())
                .openNow(restaurant.isOpenNow(now))
                .pausedUntil(restaurant.isPaused(now) ? restaurant.getPausedUntil() : null)
                .acceptanceMode(restaurant.getAcceptanceMode())
                .acceptanceTimeoutMinutes(restaurant.getAcceptanceTimeoutMinutes())
                .defaultPreparationMinutes(restaurant.getDefaultPreparationMinutes())
                .deliveryFee(restaurant.getDeliveryFee())
                .minimumOrder(restaurant.getMinimumOrder())
                .deliveryTimeMin(restaurant.getDeliveryTimeMin())
                .deliveryTimeMax(restaurant.getDeliveryTimeMax())
                .priceRange(restaurant.getPriceRange())
                .autoPrintTicket(restaurant.isAutoPrintTicket())
                .openingHours(restaurant.getOpeningHours().stream()
                        .sorted(Comparator.comparing(OpeningHour::getWeekday).thenComparing(OpeningHour::getOpenTime))
                        .map(h -> new OpeningHourDTO(h.getLabel(), h.getWeekday(), h.getOpenTime(), h.getCloseTime(),
                                h.getObservation()))
                        .toList())
                .build();
    }
}
