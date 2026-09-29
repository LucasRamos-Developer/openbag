package com.openbag.restaurant.cash.controller;

import com.openbag.platform.security.annotation.IsRestaurantOwner;
import com.openbag.restaurant.cash.dto.CashReportDTO;
import com.openbag.restaurant.cash.dto.SettleCourierRequest;
import com.openbag.restaurant.cash.dto.SettlementDTO;
import com.openbag.restaurant.cash.service.CashReportService;
import com.openbag.modules.user.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

/**
 * Caixa do restaurante: vendas pelo OpenBag e acerto com os entregadores
 */
@RestController
@RequestMapping("/restaurants/{restaurantId}/cash")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Restaurant Cash", description = "Vendas do período e acerto com os entregadores")
public class RestaurantCashController {

    @Autowired
    private CashReportService cashReportService;

    @Autowired
    private UserService userService;

    @GetMapping
    @IsRestaurantOwner
    @Operation(summary = "Caixa do período", description = "Datas locais (padrão: hoje); o acerto pendente considera todas as datas")
    public ResponseEntity<CashReportDTO> report(
            @PathVariable Long restaurantId,
            @Parameter(description = "Início (yyyy-MM-dd)") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @Parameter(description = "Fim, inclusivo (yyyy-MM-dd)") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ResponseEntity.ok(cashReportService.report(restaurantId, from, to));
    }

    @PostMapping("/settlements")
    @IsRestaurantOwner
    @Operation(summary = "Acertar com um entregador", description = "Fecha todas as entregas dele ainda não acertadas")
    public ResponseEntity<SettlementDTO> settle(@PathVariable Long restaurantId, @RequestBody SettleCourierRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(cashReportService.settle(restaurantId, request, userService.getCurrentUser()));
    }
}
