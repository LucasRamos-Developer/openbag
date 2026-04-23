package com.openbag.modules.product.controller;

import com.openbag.modules.product.entity.GlobalProduct;
import com.openbag.modules.product.service.GlobalProductService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * GlobalProductController - API para gerenciar catálogo global de produtos
 * Acesso: ADMIN para modificações, RESTAURANT_OWNER para consultas
 */
@RestController
@RequestMapping("/api/global-products")
@Tag(name = "Global Products", description = "API de gerenciamento do catálogo global de produtos")
public class GlobalProductController {

    @Autowired
    private GlobalProductService globalProductService;

    @GetMapping
    @Operation(summary = "Listar todos os produtos globais ativos")
    public ResponseEntity<List<GlobalProduct>> getAllGlobalProducts() {
        List<GlobalProduct> products = globalProductService.getAllActiveGlobalProducts();
        return ResponseEntity.ok(products);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Buscar produto global por ID")
    public ResponseEntity<GlobalProduct> getGlobalProductById(@PathVariable Long id) {
        GlobalProduct product = globalProductService.getGlobalProductById(id);
        return ResponseEntity.ok(product);
    }

    @GetMapping("/search")
    @Operation(summary = "Buscar produto global por código de barras, nome ou marca")
    public ResponseEntity<GlobalProduct> searchByBarcode(
            @Parameter(description = "Código de barras do produto")
            @RequestParam(required = false) String barcode,
            @Parameter(description = "Nome do produto")
            @RequestParam(required = false) String name,
            @Parameter(description = "Marca do produto")
            @RequestParam(required = false) String brand) {
        
        if (barcode != null && !barcode.isBlank()) {
            GlobalProduct product = globalProductService.getGlobalProductByBarcode(barcode);
            return ResponseEntity.ok(product);
        }
        
        throw new IllegalArgumentException("Forneça pelo menos um parâmetro de busca: barcode, name ou brand");
    }

    @GetMapping("/search/name")
    @Operation(summary = "Buscar produtos globais por nome")
    public ResponseEntity<List<GlobalProduct>> searchByName(
            @Parameter(description = "Nome do produto") @RequestParam String name) {
        List<GlobalProduct> products = globalProductService.searchByName(name);
        return ResponseEntity.ok(products);
    }

    @GetMapping("/search/brand")
    @Operation(summary = "Buscar produtos globais por marca")
    public ResponseEntity<List<GlobalProduct>> searchByBrand(
            @Parameter(description = "Marca do produto") @RequestParam String brand) {
        List<GlobalProduct> products = globalProductService.searchByBrand(brand);
        return ResponseEntity.ok(products);
    }

    @GetMapping("/category/{categoryId}")
    @Operation(summary = "Buscar produtos globais por categoria")
    public ResponseEntity<List<GlobalProduct>> getByCategory(@PathVariable Long categoryId) {
        List<GlobalProduct> products = globalProductService.getByCategory(categoryId);
        return ResponseEntity.ok(products);
    }

    @PostMapping
    @Operation(summary = "Criar novo produto global (ADMIN only)")
    @SecurityRequirement(name = "bearerAuth")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<GlobalProduct> createGlobalProduct(
            @Valid @RequestBody GlobalProduct globalProduct) {
        GlobalProduct savedProduct = globalProductService.createGlobalProduct(globalProduct);
        return ResponseEntity.ok(savedProduct);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Atualizar produto global (ADMIN only)")
    @SecurityRequirement(name = "bearerAuth")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<GlobalProduct> updateGlobalProduct(
            @PathVariable Long id,
            @Valid @RequestBody GlobalProduct productDetails) {
        GlobalProduct updatedProduct = globalProductService.updateGlobalProduct(id, productDetails);
        return ResponseEntity.ok(updatedProduct);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Remover produto global (soft delete - ADMIN only)")
    @SecurityRequirement(name = "bearerAuth")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteGlobalProduct(@PathVariable Long id) {
        globalProductService.deleteGlobalProduct(id);
        return ResponseEntity.noContent().build();
    }
}
