package com.openbag.modules.menu.controller;

import com.openbag.annotation.IsRestaurantOwner;
import com.openbag.modules.menu.dto.*;
import com.openbag.modules.menu.service.MenuService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

/**
 * Gestão do cardápio pelo dono do restaurante (ou ADMIN)
 */
@RestController
@RequestMapping("/restaurants/{restaurantId}/menu")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Menu", description = "Gestão do cardápio pelo restaurante: seções, itens, complementos e combos")
public class MenuController {

    @Autowired
    private MenuService menuService;

    @GetMapping
    @IsRestaurantOwner
    @Operation(summary = "Cardápio completo (visão do dono)", description = "Inclui seções e itens inativos ou esgotados")
    public ResponseEntity<MenuDTO> getMenu(@PathVariable Long restaurantId) {
        return ResponseEntity.ok(menuService.getOwnerMenu(restaurantId));
    }

    // ============= Seções =============

    @PostMapping("/sections")
    @IsRestaurantOwner
    @Operation(summary = "Criar seção")
    public ResponseEntity<MenuSectionDTO> createSection(@PathVariable Long restaurantId,
                                                        @Valid @RequestBody MenuSectionRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(menuService.createSection(restaurantId, request));
    }

    @PutMapping("/sections/{sectionId}")
    @IsRestaurantOwner
    @Operation(summary = "Atualizar seção")
    public ResponseEntity<MenuSectionDTO> updateSection(@PathVariable Long restaurantId, @PathVariable Long sectionId,
                                                        @Valid @RequestBody MenuSectionRequest request) {
        return ResponseEntity.ok(menuService.updateSection(restaurantId, sectionId, request));
    }

    @DeleteMapping("/sections/{sectionId}")
    @IsRestaurantOwner
    @Operation(summary = "Excluir seção vazia")
    public ResponseEntity<Void> deleteSection(@PathVariable Long restaurantId, @PathVariable Long sectionId) {
        menuService.deleteSection(restaurantId, sectionId);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/sections/reorder")
    @IsRestaurantOwner
    @Operation(summary = "Reordenar seções")
    public ResponseEntity<Void> reorderSections(@PathVariable Long restaurantId, @Valid @RequestBody ReorderRequest request) {
        menuService.reorderSections(restaurantId, request.getIds());
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/sections/{sectionId}/items/reorder")
    @IsRestaurantOwner
    @Operation(summary = "Reordenar itens de uma seção")
    public ResponseEntity<Void> reorderItems(@PathVariable Long restaurantId, @PathVariable Long sectionId,
                                             @Valid @RequestBody ReorderRequest request) {
        menuService.reorderItems(restaurantId, sectionId, request.getIds());
        return ResponseEntity.noContent().build();
    }

    // ============= Itens =============

    @PostMapping("/items")
    @IsRestaurantOwner
    @Operation(summary = "Criar item")
    public ResponseEntity<MenuItemDTO> createItem(@PathVariable Long restaurantId, @Valid @RequestBody MenuItemRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(menuService.createItem(restaurantId, request));
    }

    @PutMapping("/items/{itemId}")
    @IsRestaurantOwner
    @Operation(summary = "Atualizar item")
    public ResponseEntity<MenuItemDTO> updateItem(@PathVariable Long restaurantId, @PathVariable Long itemId,
                                                  @Valid @RequestBody MenuItemRequest request) {
        return ResponseEntity.ok(menuService.updateItem(restaurantId, itemId, request));
    }

    @DeleteMapping("/items/{itemId}")
    @IsRestaurantOwner
    @Operation(summary = "Excluir item", description = "Exclusão lógica: o histórico de pedidos é preservado")
    public ResponseEntity<Void> deleteItem(@PathVariable Long restaurantId, @PathVariable Long itemId) {
        menuService.deleteItem(restaurantId, itemId);
        return ResponseEntity.noContent().build();
    }

    @PatchMapping("/items/{itemId}/availability")
    @IsRestaurantOwner
    @Operation(summary = "Marcar item como esgotado ou disponível")
    public ResponseEntity<MenuItemDTO> setItemAvailability(@PathVariable Long restaurantId, @PathVariable Long itemId,
                                                           @Valid @RequestBody AvailabilityRequest request) {
        return ResponseEntity.ok(menuService.setItemAvailability(restaurantId, itemId, request.getAvailable()));
    }

    @PostMapping(value = "/items/{itemId}/image", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @IsRestaurantOwner
    @Operation(summary = "Enviar foto do item")
    public ResponseEntity<MenuItemDTO> uploadItemImage(@PathVariable Long restaurantId, @PathVariable Long itemId,
                                                       @RequestParam("file") MultipartFile file) {
        return ResponseEntity.ok(menuService.updateItemImage(restaurantId, itemId, file));
    }

    @DeleteMapping("/items/{itemId}/image")
    @IsRestaurantOwner
    @Operation(summary = "Remover foto do item")
    public ResponseEntity<MenuItemDTO> removeItemImage(@PathVariable Long restaurantId, @PathVariable Long itemId) {
        return ResponseEntity.ok(menuService.removeItemImage(restaurantId, itemId));
    }

    // ============= Complementos =============

    @PostMapping("/items/{itemId}/customization-groups")
    @IsRestaurantOwner
    @Operation(summary = "Criar grupo de complementos")
    public ResponseEntity<CustomizationGroupDTO> createGroup(@PathVariable Long restaurantId, @PathVariable Long itemId,
                                                             @Valid @RequestBody CustomizationGroupRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(menuService.createGroup(restaurantId, itemId, request));
    }

    @PutMapping("/customization-groups/{groupId}")
    @IsRestaurantOwner
    @Operation(summary = "Atualizar grupo de complementos e suas opções")
    public ResponseEntity<CustomizationGroupDTO> updateGroup(@PathVariable Long restaurantId, @PathVariable Long groupId,
                                                             @Valid @RequestBody CustomizationGroupRequest request) {
        return ResponseEntity.ok(menuService.updateGroup(restaurantId, groupId, request));
    }

    @DeleteMapping("/customization-groups/{groupId}")
    @IsRestaurantOwner
    @Operation(summary = "Excluir grupo de complementos")
    public ResponseEntity<Void> deleteGroup(@PathVariable Long restaurantId, @PathVariable Long groupId) {
        menuService.deleteGroup(restaurantId, groupId);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/items/{itemId}/customization-groups/reorder")
    @IsRestaurantOwner
    @Operation(summary = "Reordenar grupos de complementos do item")
    public ResponseEntity<Void> reorderGroups(@PathVariable Long restaurantId, @PathVariable Long itemId,
                                              @Valid @RequestBody ReorderRequest request) {
        menuService.reorderGroups(restaurantId, itemId, request.getIds());
        return ResponseEntity.noContent().build();
    }

    // ============= Combos =============

    @PostMapping("/combos")
    @IsRestaurantOwner
    @Operation(summary = "Criar combo")
    public ResponseEntity<ComboDTO> createCombo(@PathVariable Long restaurantId, @Valid @RequestBody ComboRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(menuService.createCombo(restaurantId, request));
    }

    @PutMapping("/combos/{comboId}")
    @IsRestaurantOwner
    @Operation(summary = "Atualizar combo")
    public ResponseEntity<ComboDTO> updateCombo(@PathVariable Long restaurantId, @PathVariable Long comboId,
                                                @Valid @RequestBody ComboRequest request) {
        return ResponseEntity.ok(menuService.updateCombo(restaurantId, comboId, request));
    }

    @DeleteMapping("/combos/{comboId}")
    @IsRestaurantOwner
    @Operation(summary = "Excluir combo")
    public ResponseEntity<Void> deleteCombo(@PathVariable Long restaurantId, @PathVariable Long comboId) {
        menuService.deleteCombo(restaurantId, comboId);
        return ResponseEntity.noContent().build();
    }

    @PatchMapping("/combos/{comboId}/availability")
    @IsRestaurantOwner
    @Operation(summary = "Marcar combo como esgotado ou disponível")
    public ResponseEntity<ComboDTO> setComboAvailability(@PathVariable Long restaurantId, @PathVariable Long comboId,
                                                         @Valid @RequestBody AvailabilityRequest request) {
        return ResponseEntity.ok(menuService.setComboAvailability(restaurantId, comboId, request.getAvailable()));
    }

    @PostMapping(value = "/combos/{comboId}/image", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @IsRestaurantOwner
    @Operation(summary = "Enviar foto do combo")
    public ResponseEntity<ComboDTO> uploadComboImage(@PathVariable Long restaurantId, @PathVariable Long comboId,
                                                     @RequestParam("file") MultipartFile file) {
        return ResponseEntity.ok(menuService.updateComboImage(restaurantId, comboId, file));
    }
}
