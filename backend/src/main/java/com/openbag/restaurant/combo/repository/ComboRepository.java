package com.openbag.restaurant.combo.repository;

import com.openbag.restaurant.combo.entity.Combo;
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
    // ============= Cardápio (combos não excluídos) =============

    List<Combo> findByRestaurantIdAndDeletedAtIsNullOrderByPositionAscIdAsc(Long restaurantId);

    Optional<Combo> findByIdAndRestaurantIdAndDeletedAtIsNull(Long id, Long restaurantId);

    long countByMenuSectionIdAndDeletedAtIsNull(Long menuSectionId);

    // Combos excluídos logicamente deixam de apontar para a seção (para ela poder ser apagada)
    @org.springframework.data.jpa.repository.Modifying
    @org.springframework.data.jpa.repository.Query("UPDATE Combo c SET c.menuSection = null WHERE c.menuSection.id = :sectionId AND c.deletedAt IS NOT NULL")
    void detachDeletedFromSection(@org.springframework.data.repository.query.Param("sectionId") Long sectionId);

}
