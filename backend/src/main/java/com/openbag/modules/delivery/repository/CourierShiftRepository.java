package com.openbag.modules.delivery.repository;

import com.openbag.modules.delivery.entity.CourierShift;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface CourierShiftRepository extends JpaRepository<CourierShift, Long> {

    /**
     * Turnos fixos abertos no restaurante (entregadores em check-in agora)
     */
    @Query("SELECT s FROM CourierShift s JOIN FETCH s.deliveryPerson dp JOIN FETCH dp.user "
            + "WHERE s.restaurant.id = :restaurantId AND s.mode = com.openbag.enums.ShiftMode.FIXED AND s.endedAt IS NULL")
    List<CourierShift> findOpenFixedAtRestaurant(@Param("restaurantId") Long restaurantId);

    /**
     * Turnos livres abertos sem sinal de localização desde {@code before} (app fechado ou sem internet)
     */
    @Query("SELECT s FROM CourierShift s JOIN s.deliveryPerson dp WHERE s.mode = com.openbag.enums.ShiftMode.FREE "
            + "AND s.endedAt IS NULL AND dp.workStatus = com.openbag.enums.CourierWorkStatus.ONLINE "
            + "AND (dp.lastSeenAt IS NULL OR dp.lastSeenAt < :before)")
    List<CourierShift> findStaleFreeShifts(@Param("before") LocalDateTime before);

    @Query("SELECT s FROM CourierShift s LEFT JOIN FETCH s.restaurant WHERE s.deliveryPerson.id = :deliveryPersonId "
            + "ORDER BY s.startedAt DESC")
    List<CourierShift> findRecentByCourier(@Param("deliveryPersonId") Long deliveryPersonId, Pageable pageable);
}
