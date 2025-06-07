package com.openbag.controller;

import com.openbag.entity.Category;
import com.openbag.entity.Product;
import com.openbag.service.ProductService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.List;

@RestController
@RequestMapping("/api/products")
@Tag(name = "Product", description = "API de gerenciamento de produtos")
public class ProductController {

    @Autowired
    private ProductService productService;

    @GetMapping
    @Operation(summary = "Listar todos os produtos")
    public ResponseEntity<Page<Product>> getAllProducts(
            @PageableDefault(size = 20, sort = "name", direction = Sort.Direction.ASC) Pageable pageable) {
        Page<Product> products = productService.getAllProducts(pageable);
        return ResponseEntity.ok(products);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Buscar produto por ID")
    public ResponseEntity<Product> getProductById(@PathVariable Long id) {
        Product product = productService.getProductById(id);
        return ResponseEntity.ok(product);
    }

    @GetMapping("/restaurant/{restaurantId}")
    @Operation(summary = "Listar produtos por restaurante")
    public ResponseEntity<List<Product>> getProductsByRestaurant(@PathVariable Long restaurantId) {
        List<Product> products = productService.getProductsByRestaurant(restaurantId);
        return ResponseEntity.ok(products);
    }

    @GetMapping("/category/{categoryId}")
    @Operation(summary = "Listar produtos por categoria")
    public ResponseEntity<List<Product>> getProductsByCategory(@PathVariable Long categoryId) {
        List<Product> products = productService.getProductsByCategory(categoryId);
        return ResponseEntity.ok(products);
    }

    @GetMapping("/search")
    @Operation(summary = "Pesquisar produtos")
    public ResponseEntity<List<Product>> searchProducts(
            @Parameter(description = "Termo de busca") @RequestParam String q) {
        List<Product> products = productService.searchProducts(q);
        return ResponseEntity.ok(products);
    }

    @GetMapping("/restaurant/{restaurantId}/category/{categoryId}")
    @Operation(summary = "Listar produtos por restaurante e categoria")
    public ResponseEntity<List<Product>> getProductsByRestaurantAndCategory(
            @PathVariable Long restaurantId,
            @PathVariable Long categoryId) {
        List<Product> products = productService.getProductsByRestaurantAndCategory(restaurantId, categoryId);
        return ResponseEntity.ok(products);
    }

    @PostMapping
    @Operation(summary = "Criar novo produto")
    @SecurityRequirement(name = "bearerAuth")
    @PreAuthorize("hasRole('ADMIN') or hasRole('RESTAURANT')")
    public ResponseEntity<Product> createProduct(@Valid @RequestBody Product product) {
        Product savedProduct = productService.createProduct(product);
        return ResponseEntity.ok(savedProduct);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Atualizar produto")
    @SecurityRequirement(name = "bearerAuth")
    @PreAuthorize("hasRole('ADMIN') or hasRole('RESTAURANT')")
    public ResponseEntity<Product> updateProduct(
            @PathVariable Long id,
            @Valid @RequestBody Product productDetails) {
        Product updatedProduct = productService.updateProduct(id, productDetails);
        return ResponseEntity.ok(updatedProduct);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Remover produto")
    @SecurityRequirement(name = "bearerAuth")
    @PreAuthorize("hasRole('ADMIN') or hasRole('RESTAURANT')")
    public ResponseEntity<Void> deleteProduct(@PathVariable Long id) {
        productService.deleteProduct(id);
        return ResponseEntity.noContent().build();
    }

    // Endpoints para categorias
    @GetMapping("/categories")
    @Operation(summary = "Listar todas as categorias")
    public ResponseEntity<List<Category>> getAllCategories() {
        List<Category> categories = productService.getAllCategories();
        return ResponseEntity.ok(categories);
    }

    @PostMapping("/categories")
    @Operation(summary = "Criar nova categoria")
    @SecurityRequirement(name = "bearerAuth")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Category> createCategory(@Valid @RequestBody Category category) {
        Category savedCategory = productService.createCategory(category);
        return ResponseEntity.ok(savedCategory);
    }

    @PutMapping("/categories/{id}")
    @Operation(summary = "Atualizar categoria")
    @SecurityRequirement(name = "bearerAuth")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Category> updateCategory(
            @PathVariable Long id,
            @Valid @RequestBody Category categoryDetails) {
        Category updatedCategory = productService.updateCategory(id, categoryDetails);
        return ResponseEntity.ok(updatedCategory);
    }

    @DeleteMapping("/categories/{id}")
    @Operation(summary = "Remover categoria")
    @SecurityRequirement(name = "bearerAuth")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteCategory(@PathVariable Long id) {
        productService.deleteCategory(id);
        return ResponseEntity.noContent().build();
    }
}
