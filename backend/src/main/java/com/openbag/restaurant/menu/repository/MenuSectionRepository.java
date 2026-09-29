package com.openbag.restaurant.menu.repository;

import com.openbag.restaurant.menu.entity.MenuSection;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MenuSectionRepository extends JpaRepository<MenuSection, Long> {

    List<MenuSection> findByRestaurantIdOrderByPositionAscIdAsc(Long restaurantId);

    Optional<MenuSection> findByIdAndRestaurantId(Long id, Long restaurantId);

    @Query("SELECT COALESCE(MAX(s.position), -1) FROM MenuSection s WHERE s.restaurant.id = :restaurantId")
    int findMaxPosition(@Param("restaurantId") Long restaurantId);
}
