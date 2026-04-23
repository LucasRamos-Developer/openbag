package com.openbag.service;

import com.openbag.entity.Product;
import com.openbag.entity.Restaurant;
import com.openbag.entity.User;
import com.openbag.exception.ResourceNotFoundException;
import com.openbag.repository.ProductRepository;
import com.openbag.repository.RestaurantRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional(readOnly = true)
@Slf4j
public class RestaurantService {

    @Autowired
    private RestaurantRepository restaurantRepository;

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private RoleService roleService;

    public Page<Restaurant> getAllRestaurants(Pageable pageable) {
        return restaurantRepository.findByIsActiveTrue(pageable);
    }

    public Restaurant getRestaurantById(Long id) {
        return restaurantRepository.findByIdAndIsActiveTrue(id)
                .orElseThrow(() -> new ResourceNotFoundException("Restaurante não encontrado com ID: " + id));
    }

    public List<Restaurant> searchRestaurants(String query) {
        return restaurantRepository.findByNameContainingIgnoreCaseAndIsActiveTrue(query);
    }

    public List<Restaurant> getRestaurantsByCategory(Long categoryId) {
        return restaurantRepository.findByCategory(categoryId);
    }

    public List<Restaurant> getRestaurantsNearLocation(Double latitude, Double longitude, Double radius) {
        return restaurantRepository.findNearbyRestaurants(latitude, longitude, radius);
    }

    public List<Product> getRestaurantProducts(Long restaurantId) {
        Restaurant restaurant = getRestaurantById(restaurantId);
        return productRepository.findByRestaurantAndIsActiveTrue(restaurant);
    }

    public List<Product> searchProductsInRestaurant(Long restaurantId, String query) {
        Restaurant restaurant = getRestaurantById(restaurantId);
        return productRepository.findByRestaurantAndNameContainingIgnoreCaseAndIsActiveTrue(
                restaurant, query);
    }

    public List<Product> getProductsByCategory(Long restaurantId, Long categoryId) {
        Restaurant restaurant = getRestaurantById(restaurantId);
        return productRepository.findByRestaurantAndCategoryIdAndIsActiveTrue(
                restaurant, categoryId);
    }

    @Transactional
    public Restaurant createRestaurant(Restaurant restaurant) {
        restaurant.setActive(true);
        Restaurant savedRestaurant = restaurantRepository.save(restaurant);
        
        // Auto-adiciona a role RESTAURANT_OWNER ao owner do restaurante
        if (savedRestaurant.getOwner() != null) {
            try {
                User owner = savedRestaurant.getOwner();
                if (!owner.hasRole("RESTAURANT_OWNER")) {
                    roleService.addRoleToUser(owner.getId(), "RESTAURANT_OWNER");
                    log.info("Role RESTAURANT_OWNER adicionada automaticamente ao usuário {} ao criar restaurante {}", 
                            owner.getId(), savedRestaurant.getId());
                }
            } catch (Exception e) {
                log.warn("Não foi possível adicionar role RESTAURANT_OWNER automaticamente: {}", e.getMessage());
            }
        }
        
        return savedRestaurant;
    }

    @Transactional
    public Restaurant updateRestaurant(Long id, Restaurant restaurantDetails) {
        Restaurant restaurant = getRestaurantById(id);
        
        if (restaurantDetails.getName() != null) {
            restaurant.setName(restaurantDetails.getName());
        }
        if (restaurantDetails.getDescription() != null) {
            restaurant.setDescription(restaurantDetails.getDescription());
        }
        if (restaurantDetails.getPhoneNumber() != null) {
            restaurant.setPhoneNumber(restaurantDetails.getPhoneNumber());
        }
        if (restaurantDetails.getLogoUrl() != null) {
            restaurant.setLogoUrl(restaurantDetails.getLogoUrl());
        }
        if (restaurantDetails.getBannerUrl() != null) {
            restaurant.setBannerUrl(restaurantDetails.getBannerUrl());
        }
        if (restaurantDetails.getDeliveryFee() != null) {
            restaurant.setDeliveryFee(restaurantDetails.getDeliveryFee());
        }
        if (restaurantDetails.getMinimumOrder() != null) {
            restaurant.setMinimumOrder(restaurantDetails.getMinimumOrder());
        }
        if (restaurantDetails.getDeliveryTimeMin() != null) {
            restaurant.setDeliveryTimeMin(restaurantDetails.getDeliveryTimeMin());
        }
        if (restaurantDetails.getDeliveryTimeMax() != null) {
            restaurant.setDeliveryTimeMax(restaurantDetails.getDeliveryTimeMax());
        }
        if (restaurantDetails.getAddress() != null) {
            restaurant.setAddress(restaurantDetails.getAddress());
        }
        
        return restaurantRepository.save(restaurant);
    }

    @Transactional
    public void deleteRestaurant(Long id) {
        Restaurant restaurant = getRestaurantById(id);
        restaurant.setActive(false);
        restaurantRepository.save(restaurant);
    }
}
