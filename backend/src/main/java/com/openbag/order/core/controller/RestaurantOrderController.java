package com.openbag.order.core.controller;

import com.openbag.platform.security.annotation.IsRestaurantOwner;
import com.openbag.enums.OrderStatus;
import com.openbag.order.core.dto.CreateStoreOrderRequest;
import com.openbag.order.core.dto.OrderDTO;
import com.openbag.order.core.service.OrderService;
import com.openbag.order.core.service.RestaurantOrderService;
import com.openbag.modules.organization.dto.ReasonRequest;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

/**
 * Gestor de pedidos do restaurante (e tela da cozinha)
 */
@RestController
@RequestMapping("/restaurants/{restaurantId}/orders")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Restaurant Orders", description = "Gestor de pedidos e cozinha: quadro, histórico e etapas")
public class RestaurantOrderController {

    @Autowired
    private RestaurantOrderService service;

    @Autowired
    private OrderService orderService;

    @GetMapping("/board")
    @IsRestaurantOwner
    @Operation(summary = "Pedidos ativos", description = "Novos, em preparo, prontos e em entrega (mais antigos primeiro)")
    public ResponseEntity<List<OrderDTO>> getBoard(@PathVariable Long restaurantId) {
        return ResponseEntity.ok(service.getBoard(restaurantId));
    }

    @GetMapping
    @IsRestaurantOwner
    @Operation(summary = "Histórico de pedidos de um dia")
    public ResponseEntity<Page<OrderDTO>> getHistory(
            @PathVariable Long restaurantId,
            @Parameter(description = "Dia (padrão: hoje)") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(required = false) OrderStatus status,
            @PageableDefault(size = 30) Pageable pageable) {
        return ResponseEntity.ok(service.getHistory(restaurantId, date, status, pageable));
    }

    @PostMapping
    @IsRestaurantOwner
    @Operation(summary = "Registrar pedido do balcão, telefone ou WhatsApp",
            description = "Cliente sem conta; entra já aceito e segue o fluxo dos pedidos do app. Preços recalculados pelo cardápio.")
    public ResponseEntity<OrderDTO> create(@PathVariable Long restaurantId,
                                           @Valid @RequestBody CreateStoreOrderRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(orderService.createStoreOrder(restaurantId, request));
    }

    @PostMapping("/{orderId}/accept")
    @IsRestaurantOwner
    @Operation(summary = "Aceitar pedido")
    public ResponseEntity<OrderDTO> accept(@PathVariable Long restaurantId, @PathVariable Long orderId) {
        return ResponseEntity.ok(service.accept(restaurantId, orderId));
    }

    @PostMapping("/{orderId}/reject")
    @IsRestaurantOwner
    @Operation(summary = "Recusar ou cancelar pedido", description = "O motivo é obrigatório e aparece para o cliente")
    public ResponseEntity<OrderDTO> reject(@PathVariable Long restaurantId, @PathVariable Long orderId,
                                           @Valid @RequestBody ReasonRequest request) {
        return ResponseEntity.ok(service.reject(restaurantId, orderId, request.getReason()));
    }

    @PostMapping("/{orderId}/start")
    @IsRestaurantOwner
    @Operation(summary = "Iniciar preparo")
    public ResponseEntity<OrderDTO> start(@PathVariable Long restaurantId, @PathVariable Long orderId) {
        return ResponseEntity.ok(service.start(restaurantId, orderId));
    }

    @PostMapping("/{orderId}/ready")
    @IsRestaurantOwner
    @Operation(summary = "Marcar como pronto")
    public ResponseEntity<OrderDTO> ready(@PathVariable Long restaurantId, @PathVariable Long orderId) {
        return ResponseEntity.ok(service.ready(restaurantId, orderId));
    }

    @PostMapping("/{orderId}/dispatch")
    @IsRestaurantOwner
    @Operation(summary = "Saiu para entrega")
    public ResponseEntity<OrderDTO> dispatch(@PathVariable Long restaurantId, @PathVariable Long orderId) {
        return ResponseEntity.ok(service.dispatch(restaurantId, orderId));
    }

    @PostMapping("/{orderId}/deliver")
    @IsRestaurantOwner
    @Operation(summary = "Marcar como entregue")
    public ResponseEntity<OrderDTO> deliver(@PathVariable Long restaurantId, @PathVariable Long orderId) {
        return ResponseEntity.ok(service.deliver(restaurantId, orderId));
    }
}
