package com.openbag.repository;

import com.openbag.entity.LayoutConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface LayoutConfigRepository extends JpaRepository<LayoutConfig, Long> {

    Optional<LayoutConfig> findByRestaurantId(Long restaurantId);
}
