package com.openbag.repository;

import com.openbag.entity.Product;
import com.openbag.entity.Restaurant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProductRepository extends JpaRepository<Product, Long> {

    List<Product> findByRestaurant(Restaurant restaurant);
    
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
