package com.openbag.modules.order.repository;

import com.openbag.modules.order.entity.OrderTracking;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OrderTrackingRepository extends JpaRepository<OrderTracking, Long> {

    List<OrderTracking> findByOrderId(Long orderId);

    // Método usado pelo OrderService
    List<OrderTracking> findByOrderIdOrderByTimestampAsc(Long orderId);

    @Query("SELECT ot FROM OrderTracking ot WHERE ot.order.id = :orderId ORDER BY ot.createdAt DESC")
    List<OrderTracking> findByOrderIdOrderByCreatedAtDesc(@Param("orderId") Long orderId);

    @Query("SELECT ot FROM OrderTracking ot WHERE ot.order.id = :orderId ORDER BY ot.createdAt ASC")
    List<OrderTracking> findByOrderIdOrderByCreatedAtAsc(@Param("orderId") Long orderId);
}
