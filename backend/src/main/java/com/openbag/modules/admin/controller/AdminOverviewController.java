package com.openbag.modules.admin.controller;

import com.openbag.enums.OrderStatus;
import com.openbag.modules.admin.dto.AdminDTOs.CourierRow;
import com.openbag.modules.admin.dto.AdminDTOs.OrderRow;
import com.openbag.modules.admin.dto.AdminDTOs.Overview;
import com.openbag.modules.admin.dto.AdminDTOs.RestaurantRow;
import com.openbag.modules.admin.dto.AdminDTOs.UserRow;
import com.openbag.modules.admin.service.AdminOverviewService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/admin")
@SecurityRequirement(name = "bearerAuth")
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
@Tag(name = "Admin", description = "Visão geral e listas somente leitura da plataforma (super admin)")
public class AdminOverviewController {

    private final AdminOverviewService adminService;

    @GetMapping("/overview")
    @Operation(summary = "Números da plataforma")
    public Overview overview() {
        return adminService.overview();
    }

    @GetMapping("/restaurants")
    @Operation(summary = "Restaurantes", description = "Busca por nome, slug ou e-mail do dono")
    public Page<RestaurantRow> restaurants(
            @RequestParam(required = false) String q,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        return adminService.restaurants(q, pageable);
    }

    @GetMapping("/couriers")
    @Operation(summary = "Entregadores", description = "Busca por nome ou e-mail")
    public Page<CourierRow> couriers(
            @RequestParam(required = false) String q,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        return adminService.couriers(q, pageable);
    }

    @GetMapping("/users")
    @Operation(summary = "Usuários", description = "Busca por nome ou e-mail")
    public Page<UserRow> users(
            @RequestParam(required = false) String q,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        return adminService.users(q, pageable);
    }

    @GetMapping("/orders")
    @Operation(summary = "Pedidos", description = "Filtro opcional por status")
    public Page<OrderRow> orders(
            @RequestParam(required = false) OrderStatus status,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        return adminService.orders(status, pageable);
    }
}
