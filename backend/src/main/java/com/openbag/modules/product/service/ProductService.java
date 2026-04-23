package com.openbag.modules.product.service;

import com.openbag.modules.product.dto.LinkGlobalProductRequest;
import com.openbag.modules.product.entity.Category;
import com.openbag.modules.product.entity.GlobalProduct;
import com.openbag.modules.product.entity.Product;
import com.openbag.modules.product.entity.ProductType;
import com.openbag.modules.restaurant.entity.Restaurant;
import com.openbag.modules.shared.exception.ResourceNotFoundException;
import com.openbag.modules.product.repository.CategoryRepository;
import com.openbag.modules.product.repository.GlobalProductRepository;
import com.openbag.modules.product.repository.ProductRepository;
import com.openbag.modules.restaurant.repository.RestaurantRepository;
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

    @Autowired
    private GlobalProductRepository globalProductRepository;

    public Product getProductById(Long id) {
        return productRepository.findByIdAndIsActiveTrue(id)
                .orElseThrow(() -> new ResourceNotFoundException("Produto não encontrado com ID: " + id));
    }

    public Page<Product> getAllProducts(Pageable pageable) {
        return productRepository.findByIsActiveTrue(pageable);
    }

    public List<Product> getProductsByRestaurant(Long restaurantId) {
        Restaurant restaurant = restaurantRepository.findById(restaurantId)
                .orElseThrow(() -> new ResourceNotFoundException("Restaurante não encontrado"));
        return productRepository.findByRestaurantAndIsActiveTrue(restaurant);
    }

    public List<Product> getProductsByCategory(Long categoryId) {
        Category category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new ResourceNotFoundException("Categoria não encontrada"));
        return productRepository.findByCategoryAndIsActiveTrue(category);
    }

    public List<Product> searchProducts(String query) {
        return productRepository.findByNameContainingIgnoreCaseAndIsActiveTrue(query);
    }

    public List<Product> getProductsByRestaurantAndCategory(Long restaurantId, Long categoryId) {
        Restaurant restaurant = restaurantRepository.findById(restaurantId)
                .orElseThrow(() -> new ResourceNotFoundException("Restaurante não encontrado"));
        return productRepository.findByRestaurantAndCategoryIdAndIsActiveTrue(restaurant, categoryId);
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
        if (categoryDetails.getIconUrl() != null) {
            category.setIconUrl(categoryDetails.getIconUrl());
        }
        
        return categoryRepository.save(category);
    }

    @Transactional
    public void deleteCategory(Long id) {
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Categoria não encontrada"));
        categoryRepository.delete(category);
    }

    /**
     * Vincular produto global ao restaurante com preço customizado
     */
    @Transactional
    public Product linkGlobalProductToRestaurant(Long restaurantId, LinkGlobalProductRequest request) {
        // Validar se restaurante existe
        Restaurant restaurant = restaurantRepository.findById(restaurantId)
                .orElseThrow(() -> new ResourceNotFoundException("Restaurante não encontrado"));

        // Validar se produto global existe
        GlobalProduct globalProduct = globalProductRepository.findById(request.getGlobalProductId())
                .orElseThrow(() -> new ResourceNotFoundException("Produto global não encontrado"));

        // Criar novo produto vinculado ao produto global
        Product product = new Product();
        product.setName(globalProduct.getName());
        product.setDescription(globalProduct.getDescription());
        product.setPrice(request.getRestaurantPrice());
        product.setImageUrl(globalProduct.getDefaultImageUrl());
        product.setRestaurant(restaurant);
        product.setCategory(globalProduct.getCategory());
        product.setProductType(ProductType.GLOBAL_LINKED);
        product.setGlobalProduct(globalProduct);
        product.setAvailable(request.isAvailable());
        product.setActive(true);

        return productRepository.save(product);
    }
}

