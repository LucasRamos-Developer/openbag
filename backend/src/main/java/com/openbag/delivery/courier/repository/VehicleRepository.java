package com.openbag.delivery.courier.repository;

import com.openbag.delivery.courier.entity.Vehicle;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

@Repository
public interface VehicleRepository extends JpaRepository<Vehicle, Long> {

    List<Vehicle> findByDeliveryPersonIdAndArchivedFalseOrderByCreatedAtAsc(Long deliveryPersonId);

    /** Veículos de vários entregadores de uma vez (ficha e exportação dos associados) */
    List<Vehicle> findByDeliveryPersonIdInAndArchivedFalseOrderByCreatedAtAsc(Collection<Long> deliveryPersonIds);

    Optional<Vehicle> findByIdAndDeliveryPersonIdAndArchivedFalse(Long id, Long deliveryPersonId);

    boolean existsByDeliveryPersonIdAndArchivedFalse(Long deliveryPersonId);
}
