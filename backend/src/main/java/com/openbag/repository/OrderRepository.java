package com.openbag.repository;

import com.openbag.entity.Order;
import com.openbag.entity.Restaurant;
import com.openbag.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {

    Optional<Order> findByOrderNumber(String orderNumber);
    
    // Método usado pelo OrderService
    Optional<Order> findByIdAndUserId(Long id, Long userId);
    
    // Método usado pelo OrderService  
    Page<Order> findByUserIdOrderByOrderDateDesc(Long userId, Pageable pageable);
    
    // Método usado pelo OrderService
    List<Order> findByRestaurantIdOrderByOrderDateDesc(Long restaurantId);
    
    List<Order> findByUser(User user);
    
    List<Order> findByRestaurant(Restaurant restaurant);
    
    @Query("SELECT o FROM Order o WHERE o.user = :user ORDER BY o.createdAt DESC")
    List<Order> findByUserOrderByCreatedAtDesc(@Param("user") User user);
    
    @Query("SELECT o FROM Order o WHERE o.restaurant = :restaurant " +
           "AND o.status IN ('PENDING', 'CONFIRMED', 'PREPARING') ORDER BY o.createdAt ASC")
    List<Order> findActiveOrdersByRestaurant(@Param("restaurant") Restaurant restaurant);
    
    @Query("SELECT o FROM Order o WHERE o.status = 'READY_FOR_PICKUP' AND o.deliveryPerson IS NULL")
    List<Order> findOrdersReadyForPickup();
    
    @Query("SELECT o FROM Order o WHERE o.deliveryPerson = :deliveryPerson " +
           "AND o.status IN ('OUT_FOR_DELIVERY') ORDER BY o.createdAt ASC")
    List<Order> findActiveOrdersByDeliveryPerson(@Param("deliveryPerson") com.openbag.entity.DeliveryPerson deliveryPerson);
    
    @Query("SELECT o FROM Order o WHERE o.createdAt BETWEEN :startDate AND :endDate " +
           "AND o.restaurant = :restaurant")
    List<Order> findByRestaurantAndDateRange(@Param("restaurant") Restaurant restaurant,
                                           @Param("startDate") LocalDateTime startDate,
                                           @Param("endDate") LocalDateTime endDate);
}
