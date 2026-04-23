package com.openbag.modules.restaurant.repository;

import com.openbag.modules.restaurant.entity.Restaurant;
import com.openbag.modules.user.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
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
    
    Page<Restaurant> findByIsActiveTrue(Pageable pageable);
    
    Optional<Restaurant> findByIdAndIsActiveTrue(Long id);
    
    List<Restaurant> findByNameContainingIgnoreCaseAndIsActiveTrue(String name);
    
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
    
    @Query("SELECT r FROM Restaurant r WHERE r.isActive = true " +
           "AND r.latitude IS NOT NULL AND r.longitude IS NOT NULL " +
           "AND (6371 * acos(cos(radians(:latitude)) * cos(radians(r.latitude)) " +
           "* cos(radians(r.longitude) - radians(:longitude)) " +
           "+ sin(radians(:latitude)) * sin(radians(r.latitude)))) <= :radiusKm")
    List<Restaurant> findNearbyRestaurants(@Param("latitude") Double latitude,
                                         @Param("longitude") Double longitude,
                                         @Param("radiusKm") Double radiusKm);
}
