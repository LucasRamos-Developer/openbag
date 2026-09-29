package com.openbag.restaurant.store.controller;

import com.openbag.platform.web.exception.ResourceNotFoundException;
import com.openbag.modules.delivery.dto.DeliveryQuoteDTO;
import com.openbag.modules.delivery.service.DeliveryFeeQuoteService;
import com.openbag.restaurant.menu.dto.MenuDTO;
import com.openbag.restaurant.menu.service.MenuService;
import com.openbag.restaurant.store.dto.RestaurantCardDTO;
import com.openbag.restaurant.store.dto.RestaurantPublicDTO;
import com.openbag.restaurant.store.entity.Restaurant;
import com.openbag.restaurant.store.repository.RestaurantRepository;
import com.openbag.restaurant.store.service.RestaurantService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * Consultas públicas de restaurantes e cardápio (sem login)
 */
@RestController
@RequestMapping("/public/restaurants")
@Tag(name = "Public Restaurants", description = "Restaurantes e cardápios públicos, sem autenticação")
@Transactional(readOnly = true)
public class PublicRestaurantController {

    @Autowired
    private RestaurantService restaurantService;

    @Autowired
    private RestaurantRepository restaurantRepository;

    @Autowired
    private MenuService menuService;

    @Autowired
    private Clock clock;

    @Autowired
    private DeliveryFeeQuoteService deliveryFeeQuoteService;

    @GetMapping
    @Operation(summary = "Listar restaurantes ativos")
    public ResponseEntity<Page<RestaurantCardDTO>> list(
            @PageableDefault(size = 20, sort = "name", direction = Sort.Direction.ASC) Pageable pageable) {
        LocalDateTime now = LocalDateTime.now(clock);
        Page<Restaurant> page = restaurantService.getAllRestaurants(pageable);
        Map<Long, BigDecimal> fees = deliveryFeeQuoteService.shownFees(page.getContent());
        return ResponseEntity.ok(page.map(r -> withFee(RestaurantCardDTO.from(r, now), fees.get(r.getId()))));
    }

    @GetMapping("/{idOrSlug}")
    @Operation(summary = "Página do restaurante", description = "Aceita slug ou id numérico")
    public ResponseEntity<RestaurantPublicDTO> getRestaurant(@PathVariable String idOrSlug) {
        Restaurant restaurant = findActive(idOrSlug);
        RestaurantPublicDTO dto = RestaurantPublicDTO.from(restaurant, LocalDateTime.now(clock));
        dto.setDeliveryFee(deliveryFeeQuoteService.shownFee(restaurant));
        return ResponseEntity.ok(dto);
    }

    @GetMapping("/{idOrSlug}/delivery-quote")
    @Operation(summary = "Taxa de entrega para um endereço",
            description = "Taxa fixa da loja ou, se ela repassa a taxa, o valor pela distância até o endereço")
    public ResponseEntity<DeliveryQuoteDTO> deliveryQuote(@PathVariable String idOrSlug,
                                                          @RequestParam Double lat, @RequestParam Double lng) {
        return ResponseEntity.ok(DeliveryQuoteDTO.from(deliveryFeeQuoteService.quote(findActive(idOrSlug), lat, lng)));
    }

    @GetMapping("/{idOrSlug}/menu")
    @Operation(summary = "Cardápio público",
            description = "Seções visíveis com itens e combos disponíveis, incluindo complementos")
    public ResponseEntity<MenuDTO> getMenu(@PathVariable String idOrSlug) {
        return ResponseEntity.ok(menuService.buildMenu(findActive(idOrSlug).getId(), false));
    }

    @GetMapping("/search")
    @Operation(summary = "Buscar restaurantes por nome")
    public ResponseEntity<List<RestaurantCardDTO>> search(@Parameter(description = "Termo de busca") @RequestParam String q) {
        return ResponseEntity.ok(toCards(restaurantService.searchRestaurants(q)));
    }

    @GetMapping("/category/{categoryId}")
    @Operation(summary = "Restaurantes de uma categoria")
    public ResponseEntity<List<RestaurantCardDTO>> byCategory(@PathVariable Long categoryId) {
        return ResponseEntity.ok(toCards(restaurantService.getRestaurantsByCategory(categoryId)));
    }

    @GetMapping("/nearby")
    @Operation(summary = "Restaurantes próximos")
    public ResponseEntity<List<RestaurantCardDTO>> nearby(
            @RequestParam Double lat,
            @RequestParam Double lng,
            @Parameter(description = "Raio em km") @RequestParam(defaultValue = "10.0") Double radius) {
        return ResponseEntity.ok(toCards(restaurantService.getRestaurantsNearLocation(lat, lng, radius)));
    }

    private Restaurant findActive(String idOrSlug) {
        return (idOrSlug.chars().allMatch(Character::isDigit)
                ? restaurantRepository.findByIdAndIsActiveTrue(Long.parseLong(idOrSlug))
                : restaurantRepository.findBySlugAndIsActiveTrue(idOrSlug))
                .orElseThrow(() -> new ResourceNotFoundException("Restaurante não encontrado"));
    }

    private List<RestaurantCardDTO> toCards(List<Restaurant> restaurants) {
        LocalDateTime now = LocalDateTime.now(clock);
        Map<Long, BigDecimal> fees = deliveryFeeQuoteService.shownFees(restaurants);
        return restaurants.stream().map(r -> withFee(RestaurantCardDTO.from(r, now), fees.get(r.getId()))).toList();
    }

    private static RestaurantCardDTO withFee(RestaurantCardDTO card, BigDecimal fee) {
        if (fee != null) card.setDeliveryFee(fee);
        return card;
    }
}
