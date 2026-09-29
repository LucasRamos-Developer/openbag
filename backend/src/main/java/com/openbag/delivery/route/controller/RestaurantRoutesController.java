package com.openbag.delivery.route.controller;

import com.openbag.platform.security.annotation.IsRestaurantOwner;
import com.openbag.delivery.dispatch.service.DispatchService;
import com.openbag.delivery.dispatch.dto.AssignCourierRequest;
import com.openbag.delivery.route.dto.MergeRouteRequest;
import com.openbag.delivery.route.dto.RouteSettingsDTO;
import com.openbag.delivery.route.dto.RoutesBoardDTO;
import com.openbag.delivery.route.service.RouteService;
import com.openbag.delivery.route.service.StreetRoutingService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Painel de rotas: entregas agrupadas por bairro/direção, espera por pedidos quase prontos e correções da loja
 */
@RestController
@RequestMapping("/restaurants/{restaurantId}/routes")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Restaurant Routes", description = "Rotas de entrega: acompanhar, juntar, separar, enviar agora e atribuir")
public class RestaurantRoutesController {

    @Autowired
    private RouteService routeService;

    @Autowired
    private StreetRoutingService streetRoutingService;

    @Autowired
    private DispatchService dispatchService;

    @GetMapping
    @IsRestaurantOwner
    @Operation(summary = "Rotas montando e em andamento")
    public ResponseEntity<RoutesBoardDTO> board(@PathVariable Long restaurantId) {
        // O caminho pelas ruas é buscado fora da transação do painel (consulta HTTP ao roteador)
        return ResponseEntity.ok(streetRoutingService.withStreetPaths(routeService.board(restaurantId)));
    }

    @PostMapping
    @IsRestaurantOwner
    @Operation(summary = "Juntar pedidos numa rota", description = "Sai já, procurando entregador")
    public ResponseEntity<Void> merge(@PathVariable Long restaurantId, @Valid @RequestBody MergeRouteRequest request) {
        routeService.merge(restaurantId, request.orderIds());
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{routeId}/dispatch")
    @IsRestaurantOwner
    @Operation(summary = "Chamar o entregador da rota agora")
    public ResponseEntity<Void> dispatchNow(@PathVariable Long restaurantId, @PathVariable Long routeId) {
        routeService.dispatchNow(restaurantId, routeId);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/orders/{orderId}/dispatch")
    @IsRestaurantOwner
    @Operation(summary = "Chamar o entregador de um pedido agora")
    public ResponseEntity<Void> dispatchOrderNow(@PathVariable Long restaurantId, @PathVariable Long orderId) {
        routeService.dispatchOrderNow(restaurantId, orderId);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/{routeId}/orders/{orderId}")
    @IsRestaurantOwner
    @Operation(summary = "Separar um pedido da rota", description = "Ele sai sozinho e não volta a ser agrupado")
    public ResponseEntity<Void> separate(@PathVariable Long restaurantId, @PathVariable Long routeId,
                                         @PathVariable Long orderId) {
        routeService.separate(restaurantId, routeId, orderId);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/{routeId}/courier")
    @IsRestaurantOwner
    @Operation(summary = "Atribuir a rota a um entregador", description = "Direto, sem oferta; troca segue a regra do pedido")
    public ResponseEntity<Void> assign(@PathVariable Long restaurantId, @PathVariable Long routeId,
                                       @RequestBody AssignCourierRequest request) {
        dispatchService.assignRouteDirect(restaurantId, routeId, request);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/settings")
    @IsRestaurantOwner
    @Operation(summary = "Configurações das rotas")
    public ResponseEntity<RouteSettingsDTO> updateSettings(@PathVariable Long restaurantId,
                                                           @Valid @RequestBody RouteSettingsDTO request) {
        return ResponseEntity.ok(routeService.updateSettings(restaurantId, request));
    }
}
