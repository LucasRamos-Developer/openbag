package com.openbag.modules.product.repository;

import com.openbag.modules.product.entity.Category;
import com.openbag.modules.product.entity.Product;
import com.openbag.modules.restaurant.entity.Restaurant;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProductRepository extends JpaRepository<Product, Long> {

    List<Product> findByRestaurant(Restaurant restaurant);
    
    Optional<Product> findByIdAndIsActiveTrue(Long id);
    
    Page<Product> findByIsActiveTrue(Pageable pageable);
    
    List<Product> findByRestaurantAndIsActiveTrue(Restaurant restaurant);
    
    List<Product> findByCategoryAndIsActiveTrue(Category category);
    
    List<Product> findByNameContainingIgnoreCaseAndIsActiveTrue(String name);
    
    List<Product> findByRestaurantAndCategoryIdAndIsActiveTrue(Restaurant restaurant, Long categoryId);
    
    List<Product> findByRestaurantAndNameContainingIgnoreCaseAndIsActiveTrue(Restaurant restaurant, String name);
    
    @Query("SELECT p FROM Product p WHERE p.restaurant = :restaurant " +
           "AND p.isActive = true AND p.isAvailable = true")
    List<Product> findAvailableByRestaurant(@Param("restaurant") Restaurant restaurant);
    
    @Query("SELECT p FROM Product p WHERE p.category.id = :categoryId " +
           "AND p.isActive = true AND p.isAvailable = true")
    List<Product> findByCategoryId(@Param("categoryId") Long categoryId);
    
    @Query("SELECT p FROM Product p WHERE p.restaurant.id = :restaurantId " +
           "AND LOWER(p.name) LIKE LOWER(CONCAT('%', :searchTerm, '%')) " +
           "AND p.isActive = true AND p.isAvailable = true")
    List<Product> searchByNameAndRestaurant(@Param("searchTerm") String searchTerm, 
                                          @Param("restaurantId") Long restaurantId);
    
    @Query("SELECT p FROM Product p WHERE p.restaurant.id = :restaurantId " +
           "AND p.category.id = :categoryId AND p.isActive = true AND p.isAvailable = true")
    List<Product> findByRestaurantAndCategory(@Param("restaurantId") Long restaurantId,
                                            @Param("categoryId") Long categoryId);
}
