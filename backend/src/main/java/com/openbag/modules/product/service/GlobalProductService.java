package com.openbag.modules.product.service;

import com.openbag.modules.product.entity.Category;
import com.openbag.modules.product.entity.GlobalProduct;
import com.openbag.modules.product.repository.CategoryRepository;
import com.openbag.modules.product.repository.GlobalProductRepository;
import com.openbag.modules.shared.exception.BadRequestException;
import com.openbag.modules.shared.exception.ResourceNotFoundException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * GlobalProductService - Gerenciamento do catálogo global de produtos
 * ADMIN role apenas
 */
@Service
@Transactional(readOnly = true)
public class GlobalProductService {

    @Autowired
    private GlobalProductRepository globalProductRepository;

    @Autowired
    private CategoryRepository categoryRepository;

    /**
     * Buscar produto global por ID
     */
    public GlobalProduct getGlobalProductById(Long id) {
        return globalProductRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Produto global não encontrado com ID: " + id));
    }

    /**
     * Buscar produto global por código de barras
     */
    public GlobalProduct getGlobalProductByBarcode(String barcode) {
        return globalProductRepository.findByBarcodeAndIsActiveTrue(barcode)
                .orElseThrow(() -> new ResourceNotFoundException("Produto não encontrado com código de barras: " + barcode));
    }

    /**
     * Buscar produtos globais por nome
     */
    public List<GlobalProduct> searchByName(String name) {
        return globalProductRepository.searchByName(name);
    }

    /**
     * Buscar produtos globais por categoria
     */
    public List<GlobalProduct> getByCategory(Long categoryId) {
        Category category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new ResourceNotFoundException("Categoria não encontrada"));
        return globalProductRepository.findByCategoryAndIsActiveTrue(category);
    }

    /**
     * Buscar produtos globais por marca
     */
    public List<GlobalProduct> searchByBrand(String brand) {
        return globalProductRepository.searchByBrand(brand);
    }

    /**
     * Listar todos os produtos globais ativos
     */
    public List<GlobalProduct> getAllActiveGlobalProducts() {
        return globalProductRepository.findByIsActiveTrue();
    }

    /**
     * Criar novo produto global (ADMIN only)
     */
    @Transactional
    public GlobalProduct createGlobalProduct(GlobalProduct globalProduct) {
        // Validar se código de barras já existe
        if (globalProductRepository.existsByBarcode(globalProduct.getBarcode())) {
            throw new BadRequestException("Já existe um produto com o código de barras: " + globalProduct.getBarcode());
        }

        // Validar categoria se fornecida
        if (globalProduct.getCategory() != null) {
            Category category = categoryRepository.findById(globalProduct.getCategory().getId())
                    .orElseThrow(() -> new ResourceNotFoundException("Categoria não encontrada"));
            globalProduct.setCategory(category);
        }

        globalProduct.setActive(true);
        return globalProductRepository.save(globalProduct);
    }

    /**
     * Atualizar produto global (ADMIN only)
     */
    @Transactional
    public GlobalProduct updateGlobalProduct(Long id, GlobalProduct productDetails) {
        GlobalProduct globalProduct = getGlobalProductById(id);

        if (productDetails.getName() != null) {
            globalProduct.setName(productDetails.getName());
        }
        if (productDetails.getBrand() != null) {
            globalProduct.setBrand(productDetails.getBrand());
        }
        if (productDetails.getDescription() != null) {
            globalProduct.setDescription(productDetails.getDescription());
        }
        if (productDetails.getDefaultImageUrl() != null) {
            globalProduct.setDefaultImageUrl(productDetails.getDefaultImageUrl());
        }
        if (productDetails.getCategory() != null) {
            Category category = categoryRepository.findById(productDetails.getCategory().getId())
                    .orElseThrow(() -> new ResourceNotFoundException("Categoria não encontrada"));
            globalProduct.setCategory(category);
        }

        return globalProductRepository.save(globalProduct);
    }

    /**
     * Deletar produto global (soft delete - ADMIN only)
     */
    @Transactional
    public void deleteGlobalProduct(Long id) {
        GlobalProduct globalProduct = getGlobalProductById(id);
        globalProduct.setActive(false);
        globalProductRepository.save(globalProduct);
    }
}
