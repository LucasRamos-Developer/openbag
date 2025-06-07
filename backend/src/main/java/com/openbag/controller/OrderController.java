package com.openbag.controller;

import com.openbag.entity.Order;
import com.openbag.enums.OrderStatus;
import com.openbag.entity.OrderTracking;
import com.openbag.service.OrderService;
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
@RequestMapping("/api/orders")
@Tag(name = "Order", description = "API de gerenciamento de pedidos")
@SecurityRequirement(name = "bearerAuth")
public class OrderController {

    @Autowired
    private OrderService orderService;

    @PostMapping
    @Operation(summary = "Criar novo pedido")
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<Order> createOrder(@Valid @RequestBody Order order) {
        Order savedOrder = orderService.createOrder(order);
        return ResponseEntity.ok(savedOrder);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Buscar pedido por ID")
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<Order> getOrderById(@PathVariable Long id) {
        Order order = orderService.getOrderById(id);
        return ResponseEntity.ok(order);
    }

    @GetMapping
    @Operation(summary = "Listar pedidos do usuário")
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<Page<Order>> getUserOrders(
            @PageableDefault(size = 20, sort = "orderDate", direction = Sort.Direction.DESC) Pageable pageable) {
        Page<Order> orders = orderService.getUserOrders(pageable);
        return ResponseEntity.ok(orders);
    }

    @GetMapping("/restaurant/{restaurantId}")
    @Operation(summary = "Listar pedidos do restaurante")
    @PreAuthorize("hasRole('ADMIN') or hasRole('RESTAURANT')")
    public ResponseEntity<List<Order>> getRestaurantOrders(@PathVariable Long restaurantId) {
        List<Order> orders = orderService.getRestaurantOrders(restaurantId);
        return ResponseEntity.ok(orders);
    }

    @PutMapping("/{id}/status")
    @Operation(summary = "Atualizar status do pedido")
    @PreAuthorize("hasRole('ADMIN') or hasRole('RESTAURANT')")
    public ResponseEntity<Order> updateOrderStatus(
            @PathVariable Long id,
            @Parameter(description = "Novo status do pedido") @RequestBody OrderStatusRequest request) {
        Order updatedOrder = orderService.updateOrderStatus(id, request.getStatus());
        return ResponseEntity.ok(updatedOrder);
    }

    @PutMapping("/{id}/cancel")
    @Operation(summary = "Cancelar pedido")
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<Void> cancelOrder(@PathVariable Long id) {
        orderService.cancelOrder(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{id}/tracking")
    @Operation(summary = "Acompanhar status do pedido")
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<List<OrderTracking>> getOrderTracking(@PathVariable Long id) {
        List<OrderTracking> tracking = orderService.getOrderTracking(id);
        return ResponseEntity.ok(tracking);
    }

    // DTO para atualização de status
    public static class OrderStatusRequest {
        private OrderStatus status;

        public OrderStatus getStatus() {
            return status;
        }

        public void setStatus(OrderStatus status) {
            this.status = status;
        }
    }
}
