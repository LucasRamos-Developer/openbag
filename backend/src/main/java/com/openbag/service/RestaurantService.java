package com.openbag.service;

import com.openbag.entity.Product;
import com.openbag.entity.Restaurant;
import com.openbag.exception.ResourceNotFoundException;
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
public class RestaurantService {

    @Autowired
    private RestaurantRepository restaurantRepository;

    @Autowired
    private ProductRepository productRepository;

    public Page<Restaurant> getAllRestaurants(Pageable pageable) {
        return restaurantRepository.findByActiveTrue(pageable);
    }

    public Restaurant getRestaurantById(Long id) {
        return restaurantRepository.findByIdAndActiveTrue(id)
                .orElseThrow(() -> new ResourceNotFoundException("Restaurante não encontrado com ID: " + id));
    }

    public List<Restaurant> searchRestaurants(String query) {
        return restaurantRepository.findByNameContainingIgnoreCaseAndActiveTrue(query);
    }

    public List<Restaurant> getRestaurantsByCategory(String category) {
        return restaurantRepository.findByCategoryAndActiveTrue(category);
    }

    public List<Restaurant> getRestaurantsNearLocation(Double latitude, Double longitude, Double radius) {
        return restaurantRepository.findNearbyRestaurants(latitude, longitude, radius);
    }

    public List<Product> getRestaurantProducts(Long restaurantId) {
        Restaurant restaurant = getRestaurantById(restaurantId);
        return productRepository.findByRestaurantAndActiveTrue(restaurant);
    }

    public List<Product> searchProductsInRestaurant(Long restaurantId, String query) {
        Restaurant restaurant = getRestaurantById(restaurantId);
        return productRepository.findByRestaurantAndNameContainingIgnoreCaseAndActiveTrue(
                restaurant, query);
    }

    public List<Product> getProductsByCategory(Long restaurantId, Long categoryId) {
        Restaurant restaurant = getRestaurantById(restaurantId);
        return productRepository.findByRestaurantAndCategoryIdAndActiveTrue(
                restaurant, categoryId);
    }

    @Transactional
    public Restaurant createRestaurant(Restaurant restaurant) {
        restaurant.setActive(true);
        return restaurantRepository.save(restaurant);
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
        if (restaurantDetails.getPhone() != null) {
            restaurant.setPhone(restaurantDetails.getPhone());
        }
        if (restaurantDetails.getEmail() != null) {
            restaurant.setEmail(restaurantDetails.getEmail());
        }
        if (restaurantDetails.getCategory() != null) {
            restaurant.setCategory(restaurantDetails.getCategory());
        }
        if (restaurantDetails.getImageUrl() != null) {
            restaurant.setImageUrl(restaurantDetails.getImageUrl());
        }
        if (restaurantDetails.getDeliveryFee() != null) {
            restaurant.setDeliveryFee(restaurantDetails.getDeliveryFee());
        }
        if (restaurantDetails.getMinimumOrder() != null) {
            restaurant.setMinimumOrder(restaurantDetails.getMinimumOrder());
        }
        if (restaurantDetails.getDeliveryTime() != null) {
            restaurant.setDeliveryTime(restaurantDetails.getDeliveryTime());
        }
        if (restaurantDetails.getAddress() != null) {
            restaurant.setAddress(restaurantDetails.getAddress());
        }
        if (restaurantDetails.getLatitude() != null) {
            restaurant.setLatitude(restaurantDetails.getLatitude());
        }
        if (restaurantDetails.getLongitude() != null) {
            restaurant.setLongitude(restaurantDetails.getLongitude());
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
