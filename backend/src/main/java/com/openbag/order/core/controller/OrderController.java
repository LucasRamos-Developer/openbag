package com.openbag.order.core.controller;

import com.openbag.delivery.dispatch.dto.DeliveryQuoteDTO;
import com.openbag.order.core.dto.CreateOrderRequest;
import com.openbag.order.core.dto.DeliveryQuoteRequest;
import com.openbag.order.core.dto.OrderDTO;
import com.openbag.order.core.service.OrderService;
import com.openbag.modules.user.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * Pedidos do cliente
 */
@RestController
@RequestMapping("/orders")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Order", description = "Pedidos do cliente: criar, acompanhar e cancelar")
public class OrderController {

    @Autowired
    private OrderService orderService;

    @Autowired
    private UserService userService;

    @PostMapping
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Fazer pedido",
            description = "Os preços são recalculados no servidor a partir do cardápio (promoções e complementos). " +
                    "Pagamento na entrega.")
    public ResponseEntity<OrderDTO> createOrder(@Valid @RequestBody CreateOrderRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(orderService.createOrder(request, userService.getCurrentUser()));
    }

    @PostMapping("/delivery-quote")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Taxa de entrega para o endereço",
            description = "Taxa fixa da loja ou, se ela repassa a taxa ao cliente, o valor pela distância até o endereço. "
                    + "O pedido recalcula o mesmo valor no servidor.")
    public ResponseEntity<DeliveryQuoteDTO> quoteDelivery(@Valid @RequestBody DeliveryQuoteRequest request) {
        return ResponseEntity.ok(orderService.quoteDelivery(request));
    }

    @GetMapping("/mine")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Meus pedidos", description = "Mais recentes primeiro")
    public ResponseEntity<Page<OrderDTO>> getMyOrders(@PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(orderService.getMyOrders(userService.getCurrentUser(), pageable));
    }

    @GetMapping("/{id}")
    @PreAuthorize("@authorizationService.canViewOrder(principal.id, #id)")
    @Operation(summary = "Detalhes do pedido", description = "Para o cliente, o dono do restaurante ou ADMIN")
    public ResponseEntity<OrderDTO> getOrder(@PathVariable Long id) {
        return ResponseEntity.ok(orderService.getOrder(id));
    }

    @PostMapping("/{id}/cancel")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Cancelar pedido", description = "Só enquanto o restaurante ainda não aceitou")
    public ResponseEntity<OrderDTO> cancelOrder(@PathVariable Long id) {
        return ResponseEntity.ok(orderService.cancelByCustomer(id, userService.getCurrentUser()));
    }
}
