package com.openbag.modules.restaurant.controller;

import com.openbag.annotation.IsRestaurantOwner;
import com.openbag.modules.restaurant.dto.*;
import com.openbag.modules.restaurant.service.StoreService;
import com.openbag.modules.user.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Operação da loja pelo dono do restaurante (ou ADMIN)
 */
@RestController
@RequestMapping("/restaurants")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Store", description = "Operação da loja: horários, pausa, abrir/fechar e configurações de pedido")
public class StoreController {

    @Autowired
    private StoreService storeService;

    @Autowired
    private UserService userService;

    @GetMapping("/mine")
    @PreAuthorize("hasRole('RESTAURANT_OWNER')")
    @Operation(summary = "Restaurantes do usuário logado")
    public ResponseEntity<List<RestaurantSummaryDTO>> getMyRestaurants() {
        return ResponseEntity.ok(storeService.getMyRestaurants(userService.getCurrentUser()));
    }

    @GetMapping("/{id}/store")
    @IsRestaurantOwner
    @Operation(summary = "Situação e configurações da loja")
    public ResponseEntity<StoreDTO> getStore(@PathVariable Long id) {
        return ResponseEntity.ok(storeService.getStore(id));
    }

    @PutMapping("/{id}/settings")
    @IsRestaurantOwner
    @Operation(summary = "Atualizar configurações de pedido", description = "Aceite, prazos, taxa, pedido mínimo e tempos")
    public ResponseEntity<StoreDTO> updateSettings(@PathVariable Long id, @Valid @RequestBody StoreSettingsRequest request) {
        return ResponseEntity.ok(storeService.updateSettings(id, request));
    }

    @PutMapping("/{id}/profile")
    @IsRestaurantOwner
    @Operation(summary = "Atualizar dados gerais", description = "Nome, descrição, telefone, categorias e faixa de preço (o slug não muda)")
    public ResponseEntity<StoreDTO> updateProfile(@PathVariable Long id, @Valid @RequestBody RestaurantProfileRequest request) {
        return ResponseEntity.ok(storeService.updateProfile(id, request));
    }

    @PutMapping("/{id}/address")
    @IsRestaurantOwner
    @Operation(summary = "Atualizar endereço da loja")
    public ResponseEntity<StoreDTO> updateAddress(@PathVariable Long id, @Valid @RequestBody StoreAddressRequest request) {
        return ResponseEntity.ok(storeService.updateAddress(id, request));
    }

    @PutMapping("/{id}/appearance")
    @IsRestaurantOwner
    @Operation(summary = "Atualizar a aparência da página", description = "Tema, cor da marca opcional e slogan do banner")
    public ResponseEntity<StoreDTO> updateAppearance(@PathVariable Long id, @Valid @RequestBody AppearanceRequest request) {
        return ResponseEntity.ok(storeService.updateAppearance(id, request));
    }

    @PutMapping("/{id}/opening-hours")
    @IsRestaurantOwner
    @Operation(summary = "Substituir horários de funcionamento",
            description = "Horários que viram a noite (ex: 18:00–02:00) são aceitos")
    public ResponseEntity<StoreDTO> replaceOpeningHours(@PathVariable Long id, @Valid @RequestBody OpeningHoursRequest request) {
        return ResponseEntity.ok(storeService.replaceOpeningHours(id, request.getHours()));
    }

    @PostMapping("/{id}/pause")
    @IsRestaurantOwner
    @Operation(summary = "Pausar a loja temporariamente")
    public ResponseEntity<StoreDTO> pause(@PathVariable Long id, @Valid @RequestBody PauseRequest request) {
        return ResponseEntity.ok(storeService.pause(id, request.getMinutes()));
    }

    @DeleteMapping("/{id}/pause")
    @IsRestaurantOwner
    @Operation(summary = "Encerrar a pausa")
    public ResponseEntity<StoreDTO> resume(@PathVariable Long id) {
        return ResponseEntity.ok(storeService.resume(id));
    }

    @PutMapping("/{id}/open")
    @IsRestaurantOwner
    @Operation(summary = "Abrir ou fechar a loja manualmente")
    public ResponseEntity<StoreDTO> setOpen(@PathVariable Long id, @Valid @RequestBody OpenRequest request) {
        return ResponseEntity.ok(storeService.setOpen(id, request.getOpen()));
    }
}
