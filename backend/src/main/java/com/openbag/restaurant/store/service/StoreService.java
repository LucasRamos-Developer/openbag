package com.openbag.restaurant.store.service;

import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.platform.web.exception.ResourceNotFoundException;
import com.openbag.restaurant.store.dto.AppearanceRequest;
import com.openbag.restaurant.store.dto.OpeningHourDTO;
import com.openbag.restaurant.store.dto.RestaurantProfileRequest;
import com.openbag.restaurant.store.dto.RestaurantSummaryDTO;
import com.openbag.restaurant.store.dto.StoreAddressRequest;
import com.openbag.restaurant.store.dto.StoreDTO;
import com.openbag.restaurant.store.dto.StoreSettingsRequest;
import com.openbag.restaurant.store.entity.RestaurantThemePreset;
import com.openbag.restaurant.store.entity.LayoutConfig;
import com.openbag.restaurant.store.entity.OpeningHour;
import com.openbag.restaurant.store.entity.Restaurant;
import com.openbag.restaurant.store.repository.RestaurantRepository;
import com.openbag.restaurant.catalog.entity.Category;
import com.openbag.restaurant.catalog.repository.CategoryRepository;
import com.openbag.account.dto.AddressDTO;
import com.openbag.account.entity.Address;
import com.openbag.account.entity.User;
import com.openbag.delivery.dispatch.service.RestaurantDeliveryService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;

/**
 * Operação da loja pelo dono: dados gerais, endereço, horários, pausa, abrir/fechar e configurações de pedido
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
    private CategoryRepository categoryRepository;

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
        restaurant.setAutoPrintTicket(request.isAutoPrintTicket());
        return toDTO(restaurantRepository.save(restaurant));
    }

    public StoreDTO updateProfile(Long restaurantId, RestaurantProfileRequest request) {
        Restaurant restaurant = findRestaurant(restaurantId);
        List<Category> categories = categoryRepository.findAllByIdOrThrow(request.getCategoryIds());
        restaurant.setName(request.getName().trim());
        restaurant.setDescription(blankToNull(request.getDescription()));
        restaurant.setPhoneNumber(request.getPhoneNumber().trim());
        restaurant.setPriceRange(blankToNull(request.getPriceRange()));
        // Mantém a mesma lista gerenciada pelo JPA
        restaurant.getCategories().clear();
        restaurant.getCategories().addAll(categories);
        return toDTO(restaurantRepository.save(restaurant));
    }

    public StoreDTO updateAddress(Long restaurantId, StoreAddressRequest request) {
        Restaurant restaurant = findRestaurant(restaurantId);
        Address address = restaurant.getAddress();
        if (address == null) {
            address = new Address();
            restaurant.setAddress(address);
        }
        address.setZipCode(request.getZipCode().trim());
        address.setStreet(request.getStreet().trim());
        address.setNumber(request.getNumber().trim());
        address.setComplement(blankToNull(request.getComplement()));
        address.setNeighborhood(request.getNeighborhood().trim());
        address.setCity(request.getCity().trim());
        address.setState(request.getState().trim().toUpperCase());
        address.setLatitude(request.getLatitude() != null ? request.getLatitude().doubleValue() : null);
        address.setLongitude(request.getLongitude() != null ? request.getLongitude().doubleValue() : null);
        // A busca por proximidade usa as coordenadas do próprio restaurante
        restaurant.setLatitude(request.getLatitude());
        restaurant.setLongitude(request.getLongitude());
        return toDTO(restaurantRepository.save(restaurant));
    }

    public StoreDTO updateAppearance(Long restaurantId, AppearanceRequest request) {
        Restaurant restaurant = findRestaurant(restaurantId);
        LayoutConfig layout = restaurant.getLayoutConfig();
        if (layout == null) {
            layout = new LayoutConfig();
            layout.setRestaurant(restaurant);
            restaurant.setLayoutConfig(layout);
        }
        layout.applyAppearance(request.getThemePreset(), request.getBrandColor(), request.getSlogan());
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

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private static AddressDTO toAddressDTO(Address address) {
        if (address == null) {
            return null;
        }
        AddressDTO dto = new AddressDTO(address.getStreet(), address.getNumber(), address.getComplement(),
                address.getNeighborhood(), address.getCity(), address.getState(), address.getZipCode());
        dto.setId(address.getId());
        dto.setLatitude(address.getLatitude() != null ? BigDecimal.valueOf(address.getLatitude()) : null);
        dto.setLongitude(address.getLongitude() != null ? BigDecimal.valueOf(address.getLongitude()) : null);
        return dto;
    }

    private StoreDTO toDTO(Restaurant restaurant) {
        LocalDateTime now = LocalDateTime.now(clock);
        LayoutConfig layout = restaurant.getLayoutConfig();
        return StoreDTO.builder()
                .id(restaurant.getId())
                .name(restaurant.getName())
                .slug(restaurant.getSlug())
                .logoUrl(restaurant.getLogoUrl())
                .bannerUrl(restaurant.getBannerUrl())
                .description(restaurant.getDescription())
                .phoneNumber(restaurant.getPhoneNumber())
                .cnpj(restaurant.getCnpj())
                .categoryIds(restaurant.getCategories().stream().map(Category::getId).toList())
                .categories(restaurant.getCategories().stream().map(Category::getName).toList())
                .address(toAddressDTO(restaurant.getAddress()))
                .rating(restaurant.getRating())
                .totalReviews(restaurant.getTotalReviews() != null ? restaurant.getTotalReviews() : 0)
                .themePreset(layout != null ? layout.getThemePreset() : RestaurantThemePreset.DEFAULT)
                .brandColor(layout != null ? layout.getBrandColor() : null)
                .slogan(layout != null ? layout.getSlogan() : null)
                .active(restaurant.isActive())
                .open(restaurant.isOpen())
                .openNow(restaurant.isOpenNow(now))
                .pausedUntil(restaurant.isPaused(now) ? restaurant.getPausedUntil() : null)
                .acceptanceMode(restaurant.getAcceptanceMode())
                .acceptanceTimeoutMinutes(restaurant.getAcceptanceTimeoutMinutes())
                .defaultPreparationMinutes(restaurant.getDefaultPreparationMinutes())
                .deliveryFee(restaurant.getDeliveryFee())
                .deliveryFeeMode(restaurant.getDeliveryFeeMode())
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
