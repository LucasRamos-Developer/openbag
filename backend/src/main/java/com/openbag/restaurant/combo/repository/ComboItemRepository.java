package com.openbag.restaurant.combo.repository;

import com.openbag.restaurant.combo.entity.ComboItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ComboItemRepository extends JpaRepository<ComboItem, Long> {
    
    List<ComboItem> findByComboId(Long comboId);
    
    void deleteByComboId(Long comboId);
}
