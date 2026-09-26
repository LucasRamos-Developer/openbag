package com.openbag.modules.delivery.repository;

import com.openbag.modules.delivery.entity.Vehicle;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface VehicleRepository extends JpaRepository<Vehicle, Long> {

    List<Vehicle> findByDeliveryPersonIdAndArchivedFalseOrderByCreatedAtAsc(Long deliveryPersonId);

    Optional<Vehicle> findByIdAndDeliveryPersonIdAndArchivedFalse(Long id, Long deliveryPersonId);

    boolean existsByDeliveryPersonIdAndArchivedFalse(Long deliveryPersonId);
}
