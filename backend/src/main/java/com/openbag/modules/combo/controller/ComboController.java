package com.openbag.modules.combo.controller;

import com.openbag.modules.combo.dto.ComboRequest;
import com.openbag.modules.combo.entity.Combo;
import com.openbag.modules.combo.service.ComboService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/combos")
@Tag(name = "Combos", description = "Gerenciamento de combos promocionais (pacotes de produtos)")
public class ComboController {

    @Autowired
    private ComboService comboService;

    @GetMapping("/restaurant/{restaurantId}")
    @Operation(summary = "Listar combos ativos de um restaurante")
    public ResponseEntity<List<Combo>> getCombosByRestaurant(@PathVariable Long restaurantId) {
        List<Combo> combos = comboService.getCombosByRestaurant(restaurantId);
        return ResponseEntity.ok(combos);
    }

    @GetMapping("/restaurant/{restaurantId}/available")
    @Operation(summary = "Listar combos disponíveis de um restaurante")
    public ResponseEntity<List<Combo>> getAvailableCombosByRestaurant(@PathVariable Long restaurantId) {
        List<Combo> combos = comboService.getAvailableCombosByRestaurant(restaurantId);
        return ResponseEntity.ok(combos);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Buscar combo por ID")
    public ResponseEntity<Combo> getComboById(@PathVariable Long id) {
        Combo combo = comboService.getComboById(id);
        return ResponseEntity.ok(combo);
    }

    @PostMapping
    @Operation(summary = "Criar combo promocional")
    @SecurityRequirement(name = "bearerAuth")
    @PreAuthorize("hasRole('ADMIN') or hasRole('RESTAURANT')")
    public ResponseEntity<Combo> createCombo(@Valid @RequestBody ComboRequest request) {
        Combo combo = comboService.createCombo(request);
        return ResponseEntity.ok(combo);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Atualizar combo")
    @SecurityRequirement(name = "bearerAuth")
    @PreAuthorize("hasRole('ADMIN') or hasRole('RESTAURANT')")
    public ResponseEntity<Combo> updateCombo(
            @PathVariable Long id,
            @Valid @RequestBody ComboRequest request) {
        Combo combo = comboService.updateCombo(id, request);
        return ResponseEntity.ok(combo);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Deletar combo (soft delete)")
    @SecurityRequirement(name = "bearerAuth")
    @PreAuthorize("hasRole('ADMIN') or hasRole('RESTAURANT')")
    public ResponseEntity<Void> deleteCombo(@PathVariable Long id) {
        comboService.deleteCombo(id);
        return ResponseEntity.noContent().build();
    }

    @PatchMapping("/{id}/toggle-availability")
    @Operation(summary = "Alternar disponibilidade do combo")
    @SecurityRequirement(name = "bearerAuth")
    @PreAuthorize("hasRole('ADMIN') or hasRole('RESTAURANT')")
    public ResponseEntity<Combo> toggleAvailability(@PathVariable Long id) {
        Combo combo = comboService.toggleAvailability(id);
        return ResponseEntity.ok(combo);
    }
}
