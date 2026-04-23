package com.openbag.modules.product.repository;

import com.openbag.modules.product.entity.CustomizationGroup;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CustomizationGroupRepository extends JpaRepository<CustomizationGroup, Long> {
    
    List<CustomizationGroup> findByProductId(Long productId);
    
    List<CustomizationGroup> findByProductIdOrderByIdAsc(Long productId);
}
