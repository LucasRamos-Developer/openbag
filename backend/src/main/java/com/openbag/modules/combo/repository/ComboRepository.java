package com.openbag.modules.combo.repository;

import com.openbag.modules.combo.entity.Combo;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ComboRepository extends JpaRepository<Combo, Long> {
    
    List<Combo> findByRestaurantIdAndIsActiveTrue(Long restaurantId);
    
    Page<Combo> findByRestaurantIdAndIsActiveTrue(Long restaurantId, Pageable pageable);
    
    List<Combo> findByRestaurantIdAndIsActiveTrueAndIsAvailableTrue(Long restaurantId);
    
    Optional<Combo> findByIdAndRestaurantId(Long id, Long restaurantId);
    
    List<Combo> findByCategoryIdAndIsActiveTrue(Long categoryId);
}
