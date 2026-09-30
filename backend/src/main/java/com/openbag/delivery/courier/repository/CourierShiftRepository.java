package com.openbag.delivery.courier.repository;

import com.openbag.delivery.courier.entity.CourierShift;
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
            + "WHERE s.restaurant.id = :restaurantId AND s.mode = com.openbag.delivery.courier.entity.ShiftMode.FIXED AND s.endedAt IS NULL")
    List<CourierShift> findOpenFixedAtRestaurant(@Param("restaurantId") Long restaurantId);

    /**
     * Turnos livres abertos sem sinal de localização desde {@code before} (app fechado ou sem internet)
     */
    @Query("SELECT s FROM CourierShift s JOIN s.deliveryPerson dp WHERE s.mode = com.openbag.delivery.courier.entity.ShiftMode.FREE "
            + "AND s.endedAt IS NULL AND dp.workStatus = com.openbag.delivery.courier.entity.CourierWorkStatus.ONLINE "
            + "AND (dp.lastSeenAt IS NULL OR dp.lastSeenAt < :before)")
    List<CourierShift> findStaleFreeShifts(@Param("before") LocalDateTime before);

    @Query("SELECT s FROM CourierShift s LEFT JOIN FETCH s.restaurant WHERE s.deliveryPerson.id = :deliveryPersonId "
            + "ORDER BY s.startedAt DESC")
    List<CourierShift> findRecentByCourier(@Param("deliveryPersonId") Long deliveryPersonId, Pageable pageable);

    /** Turnos do entregador que tocam [start, end): começaram antes do fim e não terminaram antes do início */
    @Query("SELECT s FROM CourierShift s WHERE s.deliveryPerson.id = :deliveryPersonId AND s.startedAt < :end "
            + "AND (s.endedAt IS NULL OR s.endedAt > :start)")
    List<CourierShift> findOverlapping(@Param("deliveryPersonId") Long deliveryPersonId,
                                       @Param("start") LocalDateTime start, @Param("end") LocalDateTime end);
}
