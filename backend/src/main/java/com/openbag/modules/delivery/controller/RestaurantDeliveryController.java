package com.openbag.modules.delivery.controller;

import com.openbag.annotation.IsRestaurantOwner;
import com.openbag.modules.delivery.dispatch.DispatchService;
import com.openbag.modules.delivery.dto.*;
import com.openbag.modules.delivery.service.CourierLinkService;
import com.openbag.modules.delivery.service.RestaurantDeliveryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Regras de entrega do restaurante: quem recebe os pedidos, associações parceiras e entregadores fixos
 */
@RestController
@RequestMapping("/restaurants/{restaurantId}/delivery")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Restaurant Delivery", description = "Política de entregadores, parceiros e entregadores fixos do restaurante")
public class RestaurantDeliveryController {

    @Autowired
    private RestaurantDeliveryService deliveryService;

    @Autowired
    private CourierLinkService linkService;

    @Autowired
    private DispatchService dispatchService;

    @GetMapping("/settings")
    @IsRestaurantOwner
    @Operation(summary = "Regras de entrega do restaurante")
    public ResponseEntity<RestaurantDeliverySettingsDTO> getSettings(@PathVariable Long restaurantId) {
        return ResponseEntity.ok(deliveryService.getSettings(restaurantId));
    }

    @PutMapping("/settings")
    @IsRestaurantOwner
    @Operation(summary = "Atualizar as regras de entrega",
            description = "Quem recebe os pedidos (todos, parceiras ou fixos), fallback e se o restaurante assume a diferença")
    public ResponseEntity<RestaurantDeliverySettingsDTO> updateSettings(
            @PathVariable Long restaurantId, @Valid @RequestBody RestaurantDeliverySettingsRequest request) {
        return ResponseEntity.ok(deliveryService.updateSettings(restaurantId, request));
    }

    @PostMapping("/partners")
    @IsRestaurantOwner
    @Operation(summary = "Adicionar associação parceira",
            description = "Recusa (409) se o valor base da associação passar da taxa e o restaurante não assumir a diferença")
    public ResponseEntity<RestaurantDeliverySettingsDTO> addPartner(@PathVariable Long restaurantId,
                                                                    @Valid @RequestBody AddPartnerRequest request) {
        return ResponseEntity.ok(deliveryService.addPartner(restaurantId, request.getOrganizationId()));
    }

    @DeleteMapping("/partners/{organizationId}")
    @IsRestaurantOwner
    @Operation(summary = "Encerrar parceria")
    public ResponseEntity<RestaurantDeliverySettingsDTO> removePartner(@PathVariable Long restaurantId,
                                                                       @PathVariable Long organizationId) {
        return ResponseEntity.ok(deliveryService.removePartner(restaurantId, organizationId));
    }

    @PostMapping("/orders/{orderId}/assign/{deliveryPersonId}")
    @IsRestaurantOwner
    @Operation(summary = "Oferecer o pedido a um fixo em check-in", description = "A oferta vai direto para o entregador escolhido")
    public ResponseEntity<Void> assign(@PathVariable Long restaurantId, @PathVariable Long orderId,
                                       @PathVariable Long deliveryPersonId) {
        dispatchService.offerToFixedCourier(restaurantId, orderId, deliveryPersonId);
        return ResponseEntity.noContent().build();
    }

    // ============= Entregadores fixos =============

    @GetMapping("/couriers")
    @IsRestaurantOwner
    @Operation(summary = "Entregadores fixos e pedidos de vínculo")
    public ResponseEntity<List<CourierLinkDTO>> listCouriers(@PathVariable Long restaurantId) {
        return ResponseEntity.ok(linkService.listForRestaurant(restaurantId));
    }

    @PostMapping("/couriers/invite")
    @IsRestaurantOwner
    @Operation(summary = "Convidar entregador para ser fixo", description = "Pelo link do perfil público do entregador")
    public ResponseEntity<CourierLinkDTO> invite(@PathVariable Long restaurantId,
                                                 @Valid @RequestBody LinkTargetRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(linkService.inviteCourier(restaurantId, request.slug()));
    }

    @PostMapping("/couriers/{linkId}/approve")
    @IsRestaurantOwner
    @Operation(summary = "Aprovar entregador fixo")
    public ResponseEntity<CourierLinkDTO> approve(@PathVariable Long restaurantId, @PathVariable Long linkId) {
        return ResponseEntity.ok(linkService.approve(restaurantId, linkId));
    }

    @PostMapping("/couriers/{linkId}/reject")
    @IsRestaurantOwner
    @Operation(summary = "Recusar pedido de vínculo")
    public ResponseEntity<CourierLinkDTO> reject(@PathVariable Long restaurantId, @PathVariable Long linkId) {
        return ResponseEntity.ok(linkService.reject(restaurantId, linkId));
    }

    @PostMapping("/couriers/{linkId}/end")
    @IsRestaurantOwner
    @Operation(summary = "Encerrar vínculo (ou cancelar convite)")
    public ResponseEntity<CourierLinkDTO> end(@PathVariable Long restaurantId, @PathVariable Long linkId) {
        return ResponseEntity.ok(linkService.endByRestaurant(restaurantId, linkId));
    }
}
