package com.openbag.modules.restaurant.controller;

import com.openbag.modules.product.entity.Product;
import com.openbag.modules.restaurant.entity.Restaurant;
import com.openbag.modules.restaurant.service.RestaurantService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controller público para visualização de restaurantes sem autenticação
 */
@RestController
@RequestMapping("/api/public/restaurants")
@Tag(name = "Public Restaurant", description = "API pública de restaurantes (sem autenticação)")
public class PublicRestaurantController {

    @Autowired
    private RestaurantService restaurantService;

    @GetMapping
    @Operation(
        summary = "Listar todos os restaurantes (público)",
        description = "Retorna uma lista paginada de todos os restaurantes cadastrados. Não requer autenticação."
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

    @GetMapping("/{idOrSlug}")
    @Operation(
        summary = "Buscar restaurante por ID ou slug (público)",
        description = "Retorna os detalhes completos de um restaurante incluindo horários de funcionamento, endereço e coordenadas. Aceita ID numérico ou slug. Não requer autenticação."
    )
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Restaurante encontrado"),
        @ApiResponse(responseCode = "404", description = "Restaurante não encontrado")
    })
    public ResponseEntity<Restaurant> getRestaurant(@PathVariable String idOrSlug) {
        Restaurant restaurant;
        
        // Tenta parsear como ID numérico primeiro
        try {
            Long id = Long.parseLong(idOrSlug);
            restaurant = restaurantService.getRestaurantById(id);
        } catch (NumberFormatException e) {
            // Se não for número, busca por slug
            restaurant = restaurantService.getRestaurantBySlug(idOrSlug);
        }
        
        return ResponseEntity.ok(restaurant);
    }

    @GetMapping("/search")
    @Operation(
        summary = "Pesquisar restaurantes por nome (público)",
        description = "Busca restaurantes cujo nome contenha o termo informado. Não requer autenticação."
    )
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Busca realizada com sucesso")
    })
    public ResponseEntity<List<Restaurant>> searchRestaurants(
            @Parameter(description = "Termo de busca") @RequestParam String q) {
        List<Restaurant> restaurants = restaurantService.searchRestaurants(q);
        return ResponseEntity.ok(restaurants);
    }

    @GetMapping("/category/{categoryId}")
    @Operation(
        summary = "Listar restaurantes por categoria (público)",
        description = "Retorna todos os restaurantes de uma categoria específica. Não requer autenticação."
    )
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Lista retornada com sucesso"),
        @ApiResponse(responseCode = "404", description = "Categoria não encontrada")
    })
    public ResponseEntity<List<Restaurant>> getRestaurantsByCategory(@PathVariable Long categoryId) {
        List<Restaurant> restaurants = restaurantService.getRestaurantsByCategory(categoryId);
        return ResponseEntity.ok(restaurants);
    }

    @GetMapping("/nearby")
    @Operation(
        summary = "Buscar restaurantes próximos (público)",
        description = "Retorna restaurantes próximos a uma coordenada geográfica dentro de um raio especificado. Não requer autenticação."
    )
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Busca realizada com sucesso")
    })
    public ResponseEntity<List<Restaurant>> getNearbyRestaurants(
            @Parameter(description = "Latitude") @RequestParam Double lat,
            @Parameter(description = "Longitude") @RequestParam Double lng,
            @Parameter(description = "Raio em quilômetros") @RequestParam(defaultValue = "10.0") Double radius) {
        List<Restaurant> restaurants = restaurantService.getRestaurantsNearLocation(lat, lng, radius);
        return ResponseEntity.ok(restaurants);
    }

    @GetMapping("/{id}/products")
    @Operation(
        summary = "Listar produtos do restaurante (público)",
        description = "Retorna todos os produtos disponíveis de um restaurante. Não requer autenticação."
    )
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Lista de produtos retornada com sucesso"),
        @ApiResponse(responseCode = "404", description = "Restaurante não encontrado")
    })
    public ResponseEntity<List<Product>> getRestaurantProducts(@PathVariable Long id) {
        List<Product> products = restaurantService.getRestaurantProducts(id);
        return ResponseEntity.ok(products);
    }

    @GetMapping("/{id}/products/search")
    @Operation(
        summary = "Pesquisar produtos no restaurante (público)",
        description = "Busca produtos de um restaurante cujo nome contenha o termo informado. Não requer autenticação."
    )
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Busca realizada com sucesso"),
        @ApiResponse(responseCode = "404", description = "Restaurante não encontrado")
    })
    public ResponseEntity<List<Product>> searchProductsInRestaurant(
            @PathVariable Long id,
            @Parameter(description = "Termo de busca") @RequestParam String q) {
        List<Product> products = restaurantService.searchProductsInRestaurant(id, q);
        return ResponseEntity.ok(products);
    }

    @GetMapping("/{id}/products/category/{categoryId}")
    @Operation(
        summary = "Listar produtos por categoria (público)",
        description = "Retorna produtos de um restaurante filtrados por categoria. Não requer autenticação."
    )
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Lista retornada com sucesso"),
        @ApiResponse(responseCode = "404", description = "Restaurante ou categoria não encontrado")
    })
    public ResponseEntity<List<Product>> getProductsByCategory(
            @PathVariable Long id,
            @PathVariable Long categoryId) {
        List<Product> products = restaurantService.getProductsByCategory(id, categoryId);
        return ResponseEntity.ok(products);
    }
}
