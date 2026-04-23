package com.openbag.modules.product.controller;

import com.openbag.modules.product.dto.LinkGlobalProductRequest;
import com.openbag.modules.product.entity.Category;
import com.openbag.modules.product.entity.Product;
import com.openbag.modules.product.service.ProductService;
import com.openbag.modules.shared.service.FileStorageService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
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
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/products")
@Tag(name = "Product", description = "API de gerenciamento de produtos")
public class ProductController {

    @Autowired
    private ProductService productService;

    @Autowired
    private FileStorageService fileStorageService;

    @GetMapping
    @Operation(
        summary = "Listar todos os produtos",
        description = "Retorna uma lista paginada de todos os produtos cadastrados no sistema"
    )
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Lista de produtos retornada com sucesso"),
        @ApiResponse(responseCode = "500", description = "Erro interno do servidor")
    })
    public ResponseEntity<Page<Product>> getAllProducts(
            @PageableDefault(size = 20, sort = "name", direction = Sort.Direction.ASC) Pageable pageable) {
        Page<Product> products = productService.getAllProducts(pageable);
        return ResponseEntity.ok(products);
    }

    @GetMapping("/{id}")
    @Operation(
        summary = "Buscar produto por ID",
        description = "Retorna os detalhes de um produto específico pelo seu ID"
    )
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Produto encontrado"),
        @ApiResponse(responseCode = "404", description = "Produto não encontrado")
    })
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

    @PostMapping("/restaurant/{restaurantId}/link-global")
    @Operation(summary = "Vincular produto global ao restaurante com preço customizado")
    @SecurityRequirement(name = "bearerAuth")
    @PreAuthorize("hasRole('ADMIN') or hasRole('RESTAURANT')")
    public ResponseEntity<Product> linkGlobalProduct(
            @PathVariable Long restaurantId,
            @Valid @RequestBody LinkGlobalProductRequest request) {
        Product product = productService.linkGlobalProductToRestaurant(restaurantId, request);
        return ResponseEntity.ok(product);
    }

    @PostMapping("/{id}/upload-image")
    @Operation(summary = "Upload de imagem do produto")
    @SecurityRequirement(name = "bearerAuth")
    @PreAuthorize("hasRole('ADMIN') or hasRole('RESTAURANT')")
    public ResponseEntity<?> uploadProductImage(
            @PathVariable Long id,
            @RequestParam("file") MultipartFile file) {
        
        // Fazer upload da imagem
        String imageUrl = fileStorageService.storeImage(file, "products");
        
        // Atualizar produto com a nova URL
        Product product = productService.getProductById(id);
        
        // Deletar imagem antiga se existir
        if (product.getImageUrl() != null && !product.getImageUrl().isEmpty()) {
            fileStorageService.deleteFile(product.getImageUrl());
        }
        
        product.setImageUrl(imageUrl);
        Product updatedProduct = productService.updateProduct(id, product);
        
        Map<String, Object> response = new HashMap<>();
        response.put("imageUrl", imageUrl);
        response.put("fullUrl", "/api/files/" + imageUrl);
        response.put("product", updatedProduct);
        
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{id}/image")
    @Operation(summary = "Remover imagem do produto")
    @SecurityRequirement(name = "bearerAuth")
    @PreAuthorize("hasRole('ADMIN') or hasRole('RESTAURANT')")
    public ResponseEntity<?> deleteProductImage(@PathVariable Long id) {
        Product product = productService.getProductById(id);
        
        if (product.getImageUrl() != null && !product.getImageUrl().isEmpty()) {
            fileStorageService.deleteFile(product.getImageUrl());
            product.setImageUrl(null);
            productService.updateProduct(id, product);
        }
        
        Map<String, String> response = new HashMap<>();
        response.put("message", "Imagem removida com sucesso");
        return ResponseEntity.ok(response);
    }
}

