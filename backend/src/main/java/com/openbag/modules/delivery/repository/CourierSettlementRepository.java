package com.openbag.modules.delivery.repository;

import com.openbag.modules.delivery.entity.CourierSettlement;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;

public interface CourierSettlementRepository extends JpaRepository<CourierSettlement, Long> {

    List<CourierSettlement> findByRestaurantIdAndSettledAtBetweenOrderBySettledAtDesc(Long restaurantId,
                                                                                      LocalDateTime start,
                                                                                      LocalDateTime end);
}
