package com.openbag.restaurant.catalog.repository;

import com.openbag.restaurant.catalog.entity.CustomizationOption;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CustomizationOptionRepository extends JpaRepository<CustomizationOption, Long> {
    
    List<CustomizationOption> findByCustomizationGroupId(Long customizationGroupId);
    
    List<CustomizationOption> findByCustomizationGroupIdAndIsAvailableTrue(Long customizationGroupId);
    
    List<CustomizationOption> findByCustomizationGroupIdOrderByDisplayOrderAsc(Long customizationGroupId);
}
