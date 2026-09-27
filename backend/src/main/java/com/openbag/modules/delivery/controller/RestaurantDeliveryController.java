package com.openbag.modules.delivery.controller;

import com.openbag.annotation.IsRestaurantOwner;
import com.openbag.modules.delivery.dispatch.DispatchService;
import com.openbag.modules.delivery.dto.*;
import com.openbag.modules.delivery.service.CourierLinkService;
import com.openbag.modules.delivery.service.RestaurantDeliveryService;
import com.openbag.modules.delivery.service.StaffCourierService;
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

    @Autowired
    private StaffCourierService staffService;

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

    // ============= Quem leva cada pedido =============

    @GetMapping("/orders/{orderId}/courier-options")
    @IsRestaurantOwner
    @Operation(summary = "Quem pode levar o pedido",
            description = "Fixos em check-in, livres online por perto e equipe própria, com valor e motivo de bloqueio; "
                    + "e se a loja pode trocar quem está com o pedido")
    public ResponseEntity<CourierOptionsDTO> courierOptions(@PathVariable Long restaurantId, @PathVariable Long orderId) {
        return ResponseEntity.ok(dispatchService.courierOptions(restaurantId, orderId));
    }

    @PutMapping("/orders/{orderId}/courier")
    @IsRestaurantOwner
    @Operation(summary = "Atribuir o pedido a um entregador",
            description = "Direto, sem oferta. Trocar: fixo e equipe a qualquer momento; livre só se não aparecer em X minutos")
    public ResponseEntity<Void> assignCourier(@PathVariable Long restaurantId, @PathVariable Long orderId,
                                              @RequestBody AssignCourierRequest request) {
        dispatchService.assignDirect(restaurantId, orderId, request);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/orders/{orderId}/courier")
    @IsRestaurantOwner
    @Operation(summary = "Tirar o entregador do pedido", description = "O pedido volta a procurar entregador")
    public ResponseEntity<Void> unassignCourier(@PathVariable Long restaurantId, @PathVariable Long orderId) {
        dispatchService.unassign(restaurantId, orderId);
        return ResponseEntity.noContent().build();
    }

    // ============= Equipe própria =============

    @GetMapping("/staff")
    @IsRestaurantOwner
    @Operation(summary = "Entregadores da equipe própria (sem o app)")
    public ResponseEntity<List<StaffCourierDTO>> listStaff(@PathVariable Long restaurantId) {
        return ResponseEntity.ok(staffService.list(restaurantId));
    }

    @PostMapping("/staff")
    @IsRestaurantOwner
    @Operation(summary = "Cadastrar entregador da equipe própria")
    public ResponseEntity<StaffCourierDTO> createStaff(@PathVariable Long restaurantId,
                                                       @Valid @RequestBody StaffCourierRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(staffService.create(restaurantId, request));
    }

    @PutMapping("/staff/{staffId}")
    @IsRestaurantOwner
    @Operation(summary = "Editar entregador da equipe própria")
    public ResponseEntity<StaffCourierDTO> updateStaff(@PathVariable Long restaurantId, @PathVariable Long staffId,
                                                       @Valid @RequestBody StaffCourierRequest request) {
        return ResponseEntity.ok(staffService.update(restaurantId, staffId, request));
    }

    @DeleteMapping("/staff/{staffId}")
    @IsRestaurantOwner
    @Operation(summary = "Remover entregador da equipe própria", description = "Só desativa: o histórico continua")
    public ResponseEntity<Void> removeStaff(@PathVariable Long restaurantId, @PathVariable Long staffId) {
        staffService.deactivate(restaurantId, staffId);
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
