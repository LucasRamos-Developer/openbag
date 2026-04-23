package com.openbag.modules.combo.service;

import com.openbag.modules.restaurant.entity.Restaurant;
import com.openbag.modules.combo.dto.ComboItemRequest;
import com.openbag.modules.combo.dto.ComboRequest;
import com.openbag.modules.combo.entity.Combo;
import com.openbag.modules.combo.entity.ComboItem;
import com.openbag.modules.combo.repository.ComboItemRepository;
import com.openbag.modules.combo.repository.ComboRepository;
import com.openbag.modules.product.entity.Category;
import com.openbag.modules.product.entity.Product;
import com.openbag.modules.product.repository.CategoryRepository;
import com.openbag.modules.product.repository.ProductRepository;
import com.openbag.modules.shared.exception.ResourceNotFoundException;
import com.openbag.modules.restaurant.repository.RestaurantRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional(readOnly = true)
public class ComboService {

    @Autowired
    private ComboRepository comboRepository;

    @Autowired
    private ComboItemRepository comboItemRepository;

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private RestaurantRepository restaurantRepository;

    @Autowired
    private CategoryRepository categoryRepository;

    /**
     * Listar combos ativos de um restaurante
     */
    public List<Combo> getCombosByRestaurant(Long restaurantId) {
        return comboRepository.findByRestaurantIdAndIsActiveTrue(restaurantId);
    }

    /**
     * Listar combos ativos e disponíveis de um restaurante
     */
    public List<Combo> getAvailableCombosByRestaurant(Long restaurantId) {
        return comboRepository.findByRestaurantIdAndIsActiveTrueAndIsAvailableTrue(restaurantId);
    }

    /**
     * Buscar combo por ID
     */
    public Combo getComboById(Long id) {
        return comboRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Combo não encontrado"));
    }

    /**
     * Criar combo
     */
    @Transactional
    public Combo createCombo(ComboRequest request) {
        Restaurant restaurant = restaurantRepository.findById(request.getRestaurantId())
                .orElseThrow(() -> new ResourceNotFoundException("Restaurante não encontrado"));

        Combo combo = new Combo();
        combo.setName(request.getName());
        combo.setDescription(request.getDescription());
        combo.setPrice(request.getPrice());
        combo.setImageUrl(request.getImageUrl());
        combo.setAvailable(request.isAvailable());
        combo.setActive(true);
        combo.setRestaurant(restaurant);

        if (request.getCategoryId() != null) {
            Category category = categoryRepository.findById(request.getCategoryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Categoria não encontrada"));
            combo.setCategory(category);
        }

        Combo savedCombo = comboRepository.save(combo);

        // Adicionar itens ao combo
        if (request.getItems() != null && !request.getItems().isEmpty()) {
            for (ComboItemRequest itemReq : request.getItems()) {
                Product product = productRepository.findById(itemReq.getProductId())
                        .orElseThrow(() -> new ResourceNotFoundException("Produto não encontrado: " + itemReq.getProductId()));

                ComboItem comboItem = new ComboItem();
                comboItem.setCombo(savedCombo);
                comboItem.setProduct(product);
                comboItem.setQuantity(itemReq.getQuantity());
                comboItem.setUnitPriceSnapshot(product.getCurrentPrice());

                comboItemRepository.save(comboItem);
            }
        }

        return comboRepository.findById(savedCombo.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Combo criado mas não encontrado"));
    }

    /**
     * Atualizar combo
     */
    @Transactional
    public Combo updateCombo(Long id, ComboRequest request) {
        Combo combo = comboRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Combo não encontrado"));

        if (request.getName() != null) {
            combo.setName(request.getName());
        }
        if (request.getDescription() != null) {
            combo.setDescription(request.getDescription());
        }
        if (request.getPrice() != null) {
            combo.setPrice(request.getPrice());
        }
        if (request.getImageUrl() != null) {
            combo.setImageUrl(request.getImageUrl());
        }
        combo.setAvailable(request.isAvailable());

        if (request.getCategoryId() != null) {
            Category category = categoryRepository.findById(request.getCategoryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Categoria não encontrada"));
            combo.setCategory(category);
        }

        // Atualizar itens se fornecido
        if (request.getItems() != null) {
            // Remover itens antigos
            comboItemRepository.deleteByComboId(combo.getId());

            // Adicionar novos itens
            for (ComboItemRequest itemReq : request.getItems()) {
                Product product = productRepository.findById(itemReq.getProductId())
                        .orElseThrow(() -> new ResourceNotFoundException("Produto não encontrado: " + itemReq.getProductId()));

                ComboItem comboItem = new ComboItem();
                comboItem.setCombo(combo);
                comboItem.setProduct(product);
                comboItem.setQuantity(itemReq.getQuantity());
                comboItem.setUnitPriceSnapshot(product.getCurrentPrice());

                comboItemRepository.save(comboItem);
            }
        }

        return comboRepository.save(combo);
    }

    /**
     * Deletar combo (soft delete)
     */
    @Transactional
    public void deleteCombo(Long id) {
        Combo combo = comboRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Combo não encontrado"));
        combo.setActive(false);
        comboRepository.save(combo);
    }

    /**
     * Alternar disponibilidade do combo
     */
    @Transactional
    public Combo toggleAvailability(Long id) {
        Combo combo = comboRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Combo não encontrado"));
        combo.setAvailable(!combo.isAvailable());
        return comboRepository.save(combo);
    }
}
