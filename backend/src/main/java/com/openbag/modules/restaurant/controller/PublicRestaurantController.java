package com.openbag.modules.restaurant.controller;

import com.openbag.exception.ResourceNotFoundException;
import com.openbag.modules.menu.dto.MenuDTO;
import com.openbag.modules.menu.service.MenuService;
import com.openbag.modules.restaurant.dto.RestaurantCardDTO;
import com.openbag.modules.restaurant.dto.RestaurantPublicDTO;
import com.openbag.modules.restaurant.entity.Restaurant;
import com.openbag.modules.restaurant.repository.RestaurantRepository;
import com.openbag.modules.restaurant.service.RestaurantService;
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

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.List;

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

    @GetMapping
    @Operation(summary = "Listar restaurantes ativos")
    public ResponseEntity<Page<RestaurantCardDTO>> list(
            @PageableDefault(size = 20, sort = "name", direction = Sort.Direction.ASC) Pageable pageable) {
        LocalDateTime now = LocalDateTime.now(clock);
        return ResponseEntity.ok(restaurantService.getAllRestaurants(pageable).map(r -> RestaurantCardDTO.from(r, now)));
    }

    @GetMapping("/{idOrSlug}")
    @Operation(summary = "Página do restaurante", description = "Aceita slug ou id numérico")
    public ResponseEntity<RestaurantPublicDTO> getRestaurant(@PathVariable String idOrSlug) {
        return ResponseEntity.ok(RestaurantPublicDTO.from(findActive(idOrSlug), LocalDateTime.now(clock)));
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
        return restaurants.stream().map(r -> RestaurantCardDTO.from(r, now)).toList();
    }
}
