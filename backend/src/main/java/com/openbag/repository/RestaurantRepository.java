package com.openbag.repository;

import com.openbag.entity.Restaurant;
import com.openbag.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface RestaurantRepository extends JpaRepository<Restaurant, Long> {

    Optional<Restaurant> findByCnpj(String cnpj);
    
    boolean existsByCnpj(String cnpj);
    
    List<Restaurant> findByOwner(User owner);
    
    @Query("SELECT r FROM Restaurant r WHERE r.isActive = true AND r.isOpen = true")
    List<Restaurant> findActiveAndOpen();
    
    @Query("SELECT r FROM Restaurant r WHERE r.isActive = true AND r.isOpen = true " +
           "AND LOWER(r.name) LIKE LOWER(CONCAT('%', :searchTerm, '%'))")
    List<Restaurant> searchByName(@Param("searchTerm") String searchTerm);
    
    @Query("SELECT r FROM Restaurant r JOIN r.categories c WHERE c.id = :categoryId " +
           "AND r.isActive = true AND r.isOpen = true")
    List<Restaurant> findByCategory(@Param("categoryId") Long categoryId);
    
    @Query("SELECT r FROM Restaurant r WHERE r.isActive = true AND r.isOpen = true " +
           "ORDER BY r.rating DESC")
    List<Restaurant> findTopRatedRestaurants();
}
