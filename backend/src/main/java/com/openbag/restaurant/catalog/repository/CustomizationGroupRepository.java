package com.openbag.restaurant.catalog.repository;

import com.openbag.restaurant.catalog.entity.CustomizationGroup;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CustomizationGroupRepository extends JpaRepository<CustomizationGroup, Long> {
    
    List<CustomizationGroup> findByProductId(Long productId);
    
    List<CustomizationGroup> findByProductIdOrderByIdAsc(Long productId);
}
