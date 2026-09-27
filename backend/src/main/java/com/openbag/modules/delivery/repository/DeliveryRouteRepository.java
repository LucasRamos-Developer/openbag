package com.openbag.modules.delivery.repository;

import com.openbag.enums.RouteStatus;
import com.openbag.modules.delivery.entity.DeliveryRoute;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface DeliveryRouteRepository extends JpaRepository<DeliveryRoute, Long> {

    @Query("SELECT DISTINCT r FROM DeliveryRoute r LEFT JOIN FETCH r.orders WHERE r.restaurant.id = :restaurantId "
            + "AND r.status IN :statuses ORDER BY r.createdAt")
    List<DeliveryRoute> findByRestaurantAndStatusIn(@Param("restaurantId") Long restaurantId,
                                                    @Param("statuses") Collection<RouteStatus> statuses);

    Optional<DeliveryRoute> findByIdAndRestaurantId(Long id, Long restaurantId);
}
