package com.openbag.modules.delivery.repository;

import com.openbag.modules.delivery.entity.StaffCourier;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface StaffCourierRepository extends JpaRepository<StaffCourier, Long> {

    List<StaffCourier> findByRestaurantIdAndActiveTrueOrderByNameAsc(Long restaurantId);

    Optional<StaffCourier> findByIdAndRestaurantId(Long id, Long restaurantId);
}
