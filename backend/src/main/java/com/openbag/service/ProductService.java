package com.openbag.service;

import com.openbag.entity.Category;
import com.openbag.entity.Product;
import com.openbag.entity.Restaurant;
import com.openbag.exception.ResourceNotFoundException;
import com.openbag.repository.CategoryRepository;
import com.openbag.repository.ProductRepository;
import com.openbag.repository.RestaurantRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional(readOnly = true)
public class ProductService {

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private RestaurantRepository restaurantRepository;

    @Autowired
    private CategoryRepository categoryRepository;

    public Product getProductById(Long id) {
        return productRepository.findByIdAndActiveTrue(id)
                .orElseThrow(() -> new ResourceNotFoundException("Produto não encontrado com ID: " + id));
    }

    public Page<Product> getAllProducts(Pageable pageable) {
        return productRepository.findByActiveTrue(pageable);
    }

    public List<Product> getProductsByRestaurant(Long restaurantId) {
        Restaurant restaurant = restaurantRepository.findById(restaurantId)
                .orElseThrow(() -> new ResourceNotFoundException("Restaurante não encontrado"));
        return productRepository.findByRestaurantAndActiveTrue(restaurant);
    }

    public List<Product> getProductsByCategory(Long categoryId) {
        Category category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new ResourceNotFoundException("Categoria não encontrada"));
        return productRepository.findByCategoryAndActiveTrue(category);
    }

    public List<Product> searchProducts(String query) {
        return productRepository.findByNameContainingIgnoreCaseAndActiveTrue(query);
    }

    public List<Product> getProductsByRestaurantAndCategory(Long restaurantId, Long categoryId) {
        Restaurant restaurant = restaurantRepository.findById(restaurantId)
                .orElseThrow(() -> new ResourceNotFoundException("Restaurante não encontrado"));
        return productRepository.findByRestaurantAndCategoryIdAndActiveTrue(restaurant, categoryId);
    }

    @Transactional
    public Product createProduct(Product product) {
        // Validar se o restaurante existe
        Restaurant restaurant = restaurantRepository.findById(product.getRestaurant().getId())
                .orElseThrow(() -> new ResourceNotFoundException("Restaurante não encontrado"));
        
        // Validar se a categoria existe
        if (product.getCategory() != null) {
            Category category = categoryRepository.findById(product.getCategory().getId())
                    .orElseThrow(() -> new ResourceNotFoundException("Categoria não encontrada"));
            product.setCategory(category);
        }
        
        product.setRestaurant(restaurant);
        product.setActive(true);
        
        return productRepository.save(product);
    }

    @Transactional
    public Product updateProduct(Long id, Product productDetails) {
        Product product = getProductById(id);
        
        if (productDetails.getName() != null) {
            product.setName(productDetails.getName());
        }
        if (productDetails.getDescription() != null) {
            product.setDescription(productDetails.getDescription());
        }
        if (productDetails.getPrice() != null) {
            product.setPrice(productDetails.getPrice());
        }
        if (productDetails.getImageUrl() != null) {
            product.setImageUrl(productDetails.getImageUrl());
        }
        if (productDetails.getCategory() != null) {
            Category category = categoryRepository.findById(productDetails.getCategory().getId())
                    .orElseThrow(() -> new ResourceNotFoundException("Categoria não encontrada"));
            product.setCategory(category);
        }
        
        return productRepository.save(product);
    }

    @Transactional
    public void deleteProduct(Long id) {
        Product product = getProductById(id);
        product.setActive(false);
        productRepository.save(product);
    }

    public List<Category> getAllCategories() {
        return categoryRepository.findAll();
    }

    @Transactional
    public Category createCategory(Category category) {
        return categoryRepository.save(category);
    }

    @Transactional
    public Category updateCategory(Long id, Category categoryDetails) {
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Categoria não encontrada"));
        
        if (categoryDetails.getName() != null) {
            category.setName(categoryDetails.getName());
        }
        if (categoryDetails.getDescription() != null) {
            category.setDescription(categoryDetails.getDescription());
        }
        if (categoryDetails.getImageUrl() != null) {
            category.setImageUrl(categoryDetails.getImageUrl());
        }
        
        return categoryRepository.save(category);
    }

    @Transactional
    public void deleteCategory(Long id) {
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Categoria não encontrada"));
        categoryRepository.delete(category);
    }
}
