package com.openbag.modules.restaurant.controller;

import com.openbag.modules.product.entity.Product;
import com.openbag.modules.restaurant.entity.Restaurant;
import com.openbag.modules.restaurant.service.RestaurantService;
import com.openbag.modules.shared.service.FileStorageService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
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
import org.springframework.web.multipart.MultipartFile;

import jakarta.validation.Valid;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/restaurants")
@Tag(name = "Restaurant", description = "API de gerenciamento de restaurantes")
public class RestaurantController {

    @Autowired
    private RestaurantService restaurantService;

    @Autowired
    private FileStorageService fileStorageService;

    @GetMapping
    @Operation(
        summary = "Listar todos os restaurantes",
        description = "Retorna uma lista paginada de todos os restaurantes cadastrados"
    )
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Lista de restaurantes retornada com sucesso"),
        @ApiResponse(responseCode = "500", description = "Erro interno do servidor")
    })
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

    @PostMapping("/{id}/upload-logo")
    @Operation(summary = "Upload do logo do restaurante")
    @SecurityRequirement(name = "bearerAuth")
    @PreAuthorize("hasRole('ADMIN') or @authorizationService.isRestaurantOwner(#id)")
    public ResponseEntity<?> uploadLogo(
            @PathVariable Long id,
            @RequestParam("file") MultipartFile file) {
        
        String logoUrl = fileStorageService.storeImage(file, "restaurants/logos");
        Restaurant restaurant = restaurantService.getRestaurantById(id);
        
        // Deletar logo antigo se existir
        if (restaurant.getLogoUrl() != null && !restaurant.getLogoUrl().isEmpty()) {
            fileStorageService.deleteFile(restaurant.getLogoUrl());
        }
        
        restaurant.setLogoUrl(logoUrl);
        Restaurant updatedRestaurant = restaurantService.updateRestaurant(id, restaurant);
        
        Map<String, Object> response = new HashMap<>();
        response.put("logoUrl", logoUrl);
        response.put("fullUrl", "/api/files/" + logoUrl);
        response.put("restaurant", updatedRestaurant);
        
        return ResponseEntity.ok(response);
    }

    @PostMapping("/{id}/upload-banner")
    @Operation(summary = "Upload do banner do restaurante")
    @SecurityRequirement(name = "bearerAuth")
    @PreAuthorize("hasRole('ADMIN') or @authorizationService.isRestaurantOwner(#id)")
    public ResponseEntity<?> uploadBanner(
            @PathVariable Long id,
            @RequestParam("file") MultipartFile file) {
        
        String bannerUrl = fileStorageService.storeImage(file, "restaurants/banners");
        Restaurant restaurant = restaurantService.getRestaurantById(id);
        
        // Deletar banner antigo se existir
        if (restaurant.getBannerUrl() != null && !restaurant.getBannerUrl().isEmpty()) {
            fileStorageService.deleteFile(restaurant.getBannerUrl());
        }
        
        restaurant.setBannerUrl(bannerUrl);
        Restaurant updatedRestaurant = restaurantService.updateRestaurant(id, restaurant);
        
        Map<String, Object> response = new HashMap<>();
        response.put("bannerUrl", bannerUrl);
        response.put("fullUrl", "/api/files/" + bannerUrl);
        response.put("restaurant", updatedRestaurant);
        
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{id}/logo")
    @Operation(summary = "Remover logo do restaurante")
    @SecurityRequirement(name = "bearerAuth")
    @PreAuthorize("hasRole('ADMIN') or @authorizationService.isRestaurantOwner(#id)")
    public ResponseEntity<?> deleteLogo(@PathVariable Long id) {
        Restaurant restaurant = restaurantService.getRestaurantById(id);
        
        if (restaurant.getLogoUrl() != null && !restaurant.getLogoUrl().isEmpty()) {
            fileStorageService.deleteFile(restaurant.getLogoUrl());
            restaurant.setLogoUrl(null);
            restaurantService.updateRestaurant(id, restaurant);
        }
        
        Map<String, String> response = new HashMap<>();
        response.put("message", "Logo removido com sucesso");
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{id}/banner")
    @Operation(summary = "Remover banner do restaurante")
    @SecurityRequirement(name = "bearerAuth")
    @PreAuthorize("hasRole('ADMIN') or @authorizationService.isRestaurantOwner(#id)")
    public ResponseEntity<?> deleteBanner(@PathVariable Long id) {
        Restaurant restaurant = restaurantService.getRestaurantById(id);
        
        if (restaurant.getBannerUrl() != null && !restaurant.getBannerUrl().isEmpty()) {
            fileStorageService.deleteFile(restaurant.getBannerUrl());
            restaurant.setBannerUrl(null);
            restaurantService.updateRestaurant(id, restaurant);
        }
        
        Map<String, String> response = new HashMap<>();
        response.put("message", "Banner removido com sucesso");
        return ResponseEntity.ok(response);
    }
}
