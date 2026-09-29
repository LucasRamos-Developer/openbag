package com.openbag.restaurant.catalog.controller;

import com.openbag.restaurant.catalog.repository.CategoryRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Categorias (tipos de cozinha) para o cadastro e a edição do restaurante, sem login
 */
@RestController
@RequestMapping("/public/categories")
@Tag(name = "Public Categories", description = "Categorias ativas, sem autenticação")
@Transactional(readOnly = true)
public class PublicCategoryController {

    public record CategoryDTO(Long id, String name, String description, String iconUrl) {}

    @Autowired
    private CategoryRepository categoryRepository;

    @GetMapping
    @Operation(summary = "Listar categorias ativas")
    public ResponseEntity<List<CategoryDTO>> list() {
        return ResponseEntity.ok(categoryRepository.findAllActive().stream()
                .map(c -> new CategoryDTO(c.getId(), c.getName(), c.getDescription(), c.getIconUrl()))
                .toList());
    }
}
