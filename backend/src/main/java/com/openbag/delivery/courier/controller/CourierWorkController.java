package com.openbag.delivery.courier.controller;

import com.openbag.delivery.courier.dto.CourierWorkStateDTO;
import com.openbag.delivery.courier.dto.LocationRequest;
import com.openbag.delivery.courier.service.CourierWorkService;
import com.openbag.modules.user.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/me/courier/work")
@SecurityRequirement(name = "bearerAuth")
@PreAuthorize("hasRole('DELIVERY_PERSON')")
@Tag(name = "Courier Work", description = "Online/offline, check-in, ofertas e entregas do entregador logado")
public class CourierWorkController {

    @Autowired
    private CourierWorkService workService;

    @Autowired
    private UserService userService;

    @GetMapping
    @Operation(summary = "Situação atual: turno, oferta pendente, entrega em andamento e ganhos do dia")
    public ResponseEntity<CourierWorkStateDTO> getState() {
        return ResponseEntity.ok(workService.getState(userService.getCurrentUser()));
    }

    @PostMapping("/online")
    @Operation(summary = "Ficar online (modo livre)")
    public ResponseEntity<CourierWorkStateDTO> goOnline(@Valid @RequestBody LocationRequest location) {
        return ResponseEntity.ok(workService.goOnline(userService.getCurrentUser(), location));
    }

    @PostMapping("/offline")
    @Operation(summary = "Ficar offline")
    public ResponseEntity<CourierWorkStateDTO> goOffline() {
        return ResponseEntity.ok(workService.goOffline(userService.getCurrentUser()));
    }

    @PutMapping("/location")
    @Operation(summary = "Enviar localização (a cada ~20 s enquanto online)")
    public ResponseEntity<Void> updateLocation(@Valid @RequestBody LocationRequest location) {
        workService.updateLocation(userService.getCurrentUser(), location);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/checkin/{restaurantId}")
    @Operation(summary = "Check-in no restaurante (entregador fixo, perto do restaurante)")
    public ResponseEntity<CourierWorkStateDTO> checkIn(@PathVariable Long restaurantId,
                                                       @Valid @RequestBody LocationRequest location) {
        return ResponseEntity.ok(workService.checkIn(userService.getCurrentUser(), restaurantId, location));
    }

    @PostMapping("/checkout")
    @Operation(summary = "Check-out do restaurante")
    public ResponseEntity<CourierWorkStateDTO> checkOut() {
        return ResponseEntity.ok(workService.checkOut(userService.getCurrentUser()));
    }

    @PostMapping("/offers/{offerId}/accept")
    @Operation(summary = "Aceitar oferta de entrega")
    public ResponseEntity<CourierWorkStateDTO> acceptOffer(@PathVariable Long offerId) {
        return ResponseEntity.ok(workService.acceptOffer(userService.getCurrentUser(), offerId));
    }

    @PostMapping("/offers/{offerId}/decline")
    @Operation(summary = "Recusar oferta de entrega")
    public ResponseEntity<CourierWorkStateDTO> declineOffer(@PathVariable Long offerId) {
        return ResponseEntity.ok(workService.declineOffer(userService.getCurrentUser(), offerId));
    }

    @PostMapping("/orders/{orderId}/pickup")
    @Operation(summary = "Retirei o pedido no restaurante")
    public ResponseEntity<CourierWorkStateDTO> pickUp(@PathVariable Long orderId) {
        return ResponseEntity.ok(workService.pickUp(userService.getCurrentUser(), orderId));
    }

    @PostMapping("/orders/{orderId}/deliver")
    @Operation(summary = "Entreguei o pedido")
    public ResponseEntity<CourierWorkStateDTO> deliver(@PathVariable Long orderId) {
        return ResponseEntity.ok(workService.deliver(userService.getCurrentUser(), orderId));
    }
}
