package com.openbag.controller;

import com.openbag.entity.Product;
import com.openbag.entity.Restaurant;
import com.openbag.service.RestaurantService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.List;

@RestController
@RequestMapping("/api/restaurants")
@Tag(name = "Restaurant", description = "API de gerenciamento de restaurantes")
public class RestaurantController {

    @Autowired
    private RestaurantService restaurantService;

    @GetMapping
    @Operation(summary = "Listar todos os restaurantes")
    public ResponseEntity<Page<Restaurant>> getAllRestaurants(
            @PageableDefault(size = 20, sort = "name", direction = Sort.Direction.ASC) Pageable pageable) {
        Page<Restaurant> restaurants = restaurantService.getAllRestaurants(pageable);
        return ResponseEntity.ok(restaurants);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Buscar restaurante por ID")
    public ResponseEntity<Restaurant> getRestaurantById(@PathVariable Long id) {
        Restaurant restaurant = restaurantService.getRestaurantById(id);
        return ResponseEntity.ok(restaurant);
    }

    @GetMapping("/search")
    @Operation(summary = "Pesquisar restaurantes por nome")
    public ResponseEntity<List<Restaurant>> searchRestaurants(
            @Parameter(description = "Termo de busca") @RequestParam String q) {
        List<Restaurant> restaurants = restaurantService.searchRestaurants(q);
        return ResponseEntity.ok(restaurants);
    }

    @GetMapping("/category/{categoryId}")
    @Operation(summary = "Listar restaurantes por categoria")
    public ResponseEntity<List<Restaurant>> getRestaurantsByCategory(@PathVariable Long categoryId) {
        List<Restaurant> restaurants = restaurantService.getRestaurantsByCategory(categoryId);
        return ResponseEntity.ok(restaurants);
    }

    @GetMapping("/nearby")
    @Operation(summary = "Buscar restaurantes próximos")
    public ResponseEntity<List<Restaurant>> getNearbyRestaurants(
            @Parameter(description = "Latitude") @RequestParam Double lat,
            @Parameter(description = "Longitude") @RequestParam Double lng,
            @Parameter(description = "Raio em quilômetros") @RequestParam(defaultValue = "10.0") Double radius) {
        List<Restaurant> restaurants = restaurantService.getRestaurantsNearLocation(lat, lng, radius);
        return ResponseEntity.ok(restaurants);
    }

    @GetMapping("/{id}/products")
    @Operation(summary = "Listar produtos do restaurante")
    public ResponseEntity<List<Product>> getRestaurantProducts(@PathVariable Long id) {
        List<Product> products = restaurantService.getRestaurantProducts(id);
        return ResponseEntity.ok(products);
    }

    @GetMapping("/{id}/products/search")
    @Operation(summary = "Pesquisar produtos no restaurante")
    public ResponseEntity<List<Product>> searchProductsInRestaurant(
            @PathVariable Long id,
            @Parameter(description = "Termo de busca") @RequestParam String q) {
        List<Product> products = restaurantService.searchProductsInRestaurant(id, q);
        return ResponseEntity.ok(products);
    }

    @GetMapping("/{id}/products/category/{categoryId}")
    @Operation(summary = "Listar produtos por categoria no restaurante")
    public ResponseEntity<List<Product>> getProductsByCategory(
            @PathVariable Long id,
            @PathVariable Long categoryId) {
        List<Product> products = restaurantService.getProductsByCategory(id, categoryId);
        return ResponseEntity.ok(products);
    }

    @PostMapping
    @Operation(summary = "Criar novo restaurante")
    @SecurityRequirement(name = "bearerAuth")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Restaurant> createRestaurant(@Valid @RequestBody Restaurant restaurant) {
        Restaurant savedRestaurant = restaurantService.createRestaurant(restaurant);
        return ResponseEntity.ok(savedRestaurant);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Atualizar restaurante")
    @SecurityRequirement(name = "bearerAuth")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Restaurant> updateRestaurant(
            @PathVariable Long id,
            @Valid @RequestBody Restaurant restaurantDetails) {
        Restaurant updatedRestaurant = restaurantService.updateRestaurant(id, restaurantDetails);
        return ResponseEntity.ok(updatedRestaurant);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Remover restaurante")
    @SecurityRequirement(name = "bearerAuth")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteRestaurant(@PathVariable Long id) {
        restaurantService.deleteRestaurant(id);
        return ResponseEntity.noContent().build();
    }
}
