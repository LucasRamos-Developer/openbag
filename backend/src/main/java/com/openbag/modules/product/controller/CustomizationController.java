package com.openbag.modules.product.controller;

import com.openbag.modules.product.dto.CustomizationGroupRequest;
import com.openbag.modules.product.dto.CustomizationOptionRequest;
import com.openbag.modules.product.entity.CustomizationGroup;
import com.openbag.modules.product.entity.CustomizationOption;
import com.openbag.modules.product.service.CustomizationService;
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
@RequestMapping("/api/customizations")
@Tag(name = "Customizações", description = "Gerenciamento de customizações de produtos (ex: Tamanho, Adicionais)")
public class CustomizationController {

    @Autowired
    private CustomizationService customizationService;

    @GetMapping("/product/{productId}")
    @Operation(summary = "Listar grupos de customização de um produto")
    public ResponseEntity<List<CustomizationGroup>> getCustomizationGroups(@PathVariable Long productId) {
        List<CustomizationGroup> groups = customizationService.getCustomizationGroupsByProductId(productId);
        return ResponseEntity.ok(groups);
    }

    @PostMapping("/groups")
    @Operation(summary = "Criar grupo de customização para um produto")
    @SecurityRequirement(name = "bearerAuth")
    @PreAuthorize("hasRole('ADMIN') or hasRole('RESTAURANT')")
    public ResponseEntity<CustomizationGroup> createCustomizationGroup(
            @Valid @RequestBody CustomizationGroupRequest request) {
        CustomizationGroup group = customizationService.createCustomizationGroup(request);
        return ResponseEntity.ok(group);
    }

    @PutMapping("/groups/{id}")
    @Operation(summary = "Atualizar grupo de customização")
    @SecurityRequirement(name = "bearerAuth")
    @PreAuthorize("hasRole('ADMIN') or hasRole('RESTAURANT')")
    public ResponseEntity<CustomizationGroup> updateCustomizationGroup(
            @PathVariable Long id,
            @Valid @RequestBody CustomizationGroupRequest request) {
        CustomizationGroup group = customizationService.updateCustomizationGroup(id, request);
        return ResponseEntity.ok(group);
    }

    @DeleteMapping("/groups/{id}")
    @Operation(summary = "Deletar grupo de customização")
    @SecurityRequirement(name = "bearerAuth")
    @PreAuthorize("hasRole('ADMIN') or hasRole('RESTAURANT')")
    public ResponseEntity<Void> deleteCustomizationGroup(@PathVariable Long id) {
        customizationService.deleteCustomizationGroup(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/groups/{groupId}/options")
    @Operation(summary = "Adicionar opção a um grupo de customização")
    @SecurityRequirement(name = "bearerAuth")
    @PreAuthorize("hasRole('ADMIN') or hasRole('RESTAURANT')")
    public ResponseEntity<CustomizationOption> addOption(
            @PathVariable Long groupId,
            @Valid @RequestBody CustomizationOptionRequest request) {
        CustomizationOption option = customizationService.addOptionToGroup(groupId, request);
        return ResponseEntity.ok(option);
    }

    @GetMapping("/groups/{groupId}/options")
    @Operation(summary = "Listar opções de um grupo de customização")
    public ResponseEntity<List<CustomizationOption>> getOptionsByGroup(@PathVariable Long groupId) {
        List<CustomizationOption> options = customizationService.getOptionsByGroupId(groupId);
        return ResponseEntity.ok(options);
    }

    @PutMapping("/options/{optionId}")
    @Operation(summary = "Atualizar opção de customização")
    @SecurityRequirement(name = "bearerAuth")
    @PreAuthorize("hasRole('ADMIN') or hasRole('RESTAURANT')")
    public ResponseEntity<CustomizationOption> updateOption(
            @PathVariable Long optionId,
            @Valid @RequestBody CustomizationOptionRequest request) {
        CustomizationOption option = customizationService.updateCustomizationOption(optionId, request);
        return ResponseEntity.ok(option);
    }

    @DeleteMapping("/options/{optionId}")
    @Operation(summary = "Deletar opção de customização")
    @SecurityRequirement(name = "bearerAuth")
    @PreAuthorize("hasRole('ADMIN') or hasRole('RESTAURANT')")
    public ResponseEntity<Void> deleteOption(@PathVariable Long optionId) {
        customizationService.deleteCustomizationOption(optionId);
        return ResponseEntity.noContent().build();
    }
}
