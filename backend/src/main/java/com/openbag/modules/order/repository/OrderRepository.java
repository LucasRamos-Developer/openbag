package com.openbag.modules.order.repository;

import com.openbag.modules.order.entity.Order;
import com.openbag.modules.restaurant.entity.Restaurant;
import com.openbag.modules.delivery.entity.DeliveryPerson;
import com.openbag.enums.OrderStatus;
import com.openbag.modules.user.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {

    /** Retirada na loja não passa pelo despacho nem pelas rotas (nulo = pedido antigo, de entrega) */
    String NOT_PICKUP = "AND (o.fulfillment IS NULL OR o.fulfillment <> com.openbag.enums.FulfillmentType.PICKUP)";

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
    List<Order> findActiveOrdersByDeliveryPerson(@Param("deliveryPerson") DeliveryPerson deliveryPerson);
    
    @Query("SELECT o FROM Order o WHERE o.createdAt BETWEEN :startDate AND :endDate " +
           "AND o.restaurant = :restaurant")
    List<Order> findByRestaurantAndDateRange(@Param("restaurant") Restaurant restaurant,
                                           @Param("startDate") LocalDateTime startDate,
                                           @Param("endDate") LocalDateTime endDate);
    @Query("SELECT COALESCE(MAX(o.dailyNumber), 0) FROM Order o WHERE o.restaurant.id = :restaurantId AND o.orderDate >= :startOfDay")
    int findMaxDailyNumber(@Param("restaurantId") Long restaurantId, @Param("startOfDay") java.time.LocalDateTime startOfDay);

    // ============= Gestão de pedidos do restaurante =============

    Optional<Order> findByIdAndRestaurantId(Long id, Long restaurantId);

    List<Order> findByRestaurantIdAndStatusInOrderByOrderDateAsc(Long restaurantId, java.util.Collection<OrderStatus> statuses);

    Page<Order> findByRestaurantIdAndOrderDateBetweenOrderByOrderDateDesc(Long restaurantId, java.time.LocalDateTime start,
                                                                         java.time.LocalDateTime end, Pageable pageable);

    Page<Order> findByRestaurantIdAndStatusAndOrderDateBetweenOrderByOrderDateDesc(Long restaurantId, OrderStatus status,
                                                                                   java.time.LocalDateTime start,
                                                                                   java.time.LocalDateTime end, Pageable pageable);

    // Pedidos que o restaurante não aceitou dentro do prazo
    List<Order> findByStatusAndAcceptDeadlineBefore(OrderStatus status, java.time.LocalDateTime now);

    // ============= Entregas pelo entregador do app =============

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT o FROM Order o WHERE o.id = :id")
    Optional<Order> findByIdForUpdate(@Param("id") Long id);

    /**
     * Pedidos aceitos que ainda esperam entregador
     */
    @Query("SELECT o.id FROM Order o WHERE o.deliveryPerson IS NULL AND o.staffCourier IS NULL AND o.status IN :statuses "
            + NOT_PICKUP)
    List<Long> findIdsAwaitingCourier(@Param("statuses") java.util.Collection<OrderStatus> statuses);

    /**
     * Entrega em andamento do entregador (aceita e ainda não entregue)
     */
    @Query("SELECT o FROM Order o WHERE o.deliveryPerson.id = :deliveryPersonId AND o.status IN :statuses "
            + "ORDER BY o.assignedAt DESC")
    List<Order> findByCourierAndStatusIn(@Param("deliveryPersonId") Long deliveryPersonId,
                                         @Param("statuses") java.util.Collection<OrderStatus> statuses);

    /**
     * Soma do valor das entregas concluídas por entregador no período: [deliveryPersonId, soma]
     */
    @Query("SELECT o.deliveryPerson.id, COALESCE(SUM(o.courierFee), 0) FROM Order o "
            + "WHERE o.deliveryPerson.id IN :ids AND o.status = com.openbag.enums.OrderStatus.DELIVERED "
            + "AND o.deliveredAt >= :start AND o.deliveredAt < :end GROUP BY o.deliveryPerson.id")
    List<Object[]> sumCourierFeesBetween(@Param("ids") java.util.Collection<Long> ids,
                                         @Param("start") LocalDateTime start, @Param("end") LocalDateTime end);

    @Query("SELECT COUNT(o) FROM Order o WHERE o.deliveryPerson.id = :deliveryPersonId "
            + "AND o.status = com.openbag.enums.OrderStatus.DELIVERED AND o.deliveredAt >= :start AND o.deliveredAt < :end")
    long countDeliveredBetween(@Param("deliveryPersonId") Long deliveryPersonId,
                               @Param("start") LocalDateTime start, @Param("end") LocalDateTime end);

    /**
     * Entregas concluídas pelo entregador no período (mais recentes primeiro)
     */
    @Query("SELECT o FROM Order o JOIN FETCH o.restaurant WHERE o.deliveryPerson.id = :deliveryPersonId "
            + "AND o.status = com.openbag.enums.OrderStatus.DELIVERED AND o.deliveredAt >= :start AND o.deliveredAt < :end "
            + "ORDER BY o.deliveredAt DESC")
    List<Order> findDeliveredByCourierBetween(@Param("deliveryPersonId") Long deliveryPersonId,
                                              @Param("start") LocalDateTime start, @Param("end") LocalDateTime end);

    /**
     * Restaurantes em que o entregador fez entregas: [restaurantId, quantidade, primeira, última]
     */
    @Query("SELECT o.restaurant.id, COUNT(o), MIN(o.deliveredAt), MAX(o.deliveredAt) FROM Order o "
            + "WHERE o.deliveryPerson.id = :deliveryPersonId AND o.status = com.openbag.enums.OrderStatus.DELIVERED "
            + "GROUP BY o.restaurant.id ORDER BY MAX(o.deliveredAt) DESC")
    List<Object[]> summarizeRestaurantsByCourier(@Param("deliveryPersonId") Long deliveryPersonId);

    // ============= Caixa do restaurante =============

    /**
     * Pedidos entregues no período, com quem levou (para o caixa)
     */
    @Query("SELECT o FROM Order o LEFT JOIN FETCH o.deliveryPerson dp LEFT JOIN FETCH dp.user "
            + "LEFT JOIN FETCH dp.organization LEFT JOIN FETCH o.courierOrganization LEFT JOIN FETCH o.staffCourier "
            + "WHERE o.restaurant.id = :restaurantId "
            + "AND o.status = com.openbag.enums.OrderStatus.DELIVERED AND o.deliveredAt >= :start AND o.deliveredAt < :end")
    List<Order> findDeliveredByRestaurantBetween(@Param("restaurantId") Long restaurantId,
                                                @Param("start") LocalDateTime start, @Param("end") LocalDateTime end);

    /** Entregas feitas pelos cooperados da associação no período (pela associação registrada no pedido) */
    @Query("SELECT o FROM Order o JOIN FETCH o.restaurant JOIN FETCH o.deliveryPerson dp JOIN FETCH dp.user "
            + "WHERE o.courierOrganization.id = :organizationId "
            + "AND o.status = com.openbag.enums.OrderStatus.DELIVERED AND o.deliveredAt >= :start AND o.deliveredAt < :end "
            + "ORDER BY o.deliveredAt")
    List<Order> findDeliveredByOrganizationBetween(@Param("organizationId") Long organizationId,
                                                   @Param("start") LocalDateTime start, @Param("end") LocalDateTime end);

    /** Ganhos e entregas de cada cooperado no período: [deliveryPersonId, soma do courierFee, entregas] */
    @Query("SELECT o.deliveryPerson.id, COALESCE(SUM(o.courierFee), 0), COUNT(o) FROM Order o "
            + "WHERE o.courierOrganization.id = :organizationId "
            + "AND o.status = com.openbag.enums.OrderStatus.DELIVERED AND o.deliveredAt >= :start AND o.deliveredAt < :end "
            + "GROUP BY o.deliveryPerson.id")
    List<Object[]> sumCourierEarningsByCourier(@Param("organizationId") Long organizationId,
                                               @Param("start") LocalDateTime start, @Param("end") LocalDateTime end);

    /** Registra a associação atual do entregador nos pedidos anteriores ao campo (uma vez, na subida) */
    @Modifying
    @Query(value = "UPDATE orders o SET courier_organization_id = dp.organization_id FROM delivery_persons dp "
            + "WHERE dp.id = o.delivery_person_id AND o.courier_organization_id IS NULL "
            + "AND dp.organization_id IS NOT NULL", nativeQuery = true)
    int backfillCourierOrganization();

    @Query("SELECT COUNT(o) FROM Order o WHERE o.restaurant.id = :restaurantId "
            + "AND o.status = com.openbag.enums.OrderStatus.CANCELLED AND o.cancelledAt >= :start AND o.cancelledAt < :end")
    long countCancelledByRestaurantBetween(@Param("restaurantId") Long restaurantId,
                                           @Param("start") LocalDateTime start, @Param("end") LocalDateTime end);

    /**
     * Entregas concluídas ainda sem acerto com o entregador (de qualquer data)
     */
    @Query("SELECT o FROM Order o LEFT JOIN FETCH o.deliveryPerson dp LEFT JOIN FETCH dp.user "
            + "LEFT JOIN FETCH o.staffCourier WHERE o.restaurant.id = :restaurantId "
            + "AND o.status = com.openbag.enums.OrderStatus.DELIVERED AND o.settlement IS NULL "
            + "AND (o.deliveryPerson IS NOT NULL OR o.staffCourier IS NOT NULL)")
    List<Order> findUnsettledByRestaurant(@Param("restaurantId") Long restaurantId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT o FROM Order o WHERE o.restaurant.id = :restaurantId AND o.deliveryPerson.id = :deliveryPersonId "
            + "AND o.status = com.openbag.enums.OrderStatus.DELIVERED AND o.settlement IS NULL")
    List<Order> findUnsettledForAppCourierForUpdate(@Param("restaurantId") Long restaurantId,
                                                    @Param("deliveryPersonId") Long deliveryPersonId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT o FROM Order o WHERE o.restaurant.id = :restaurantId AND o.staffCourier.id = :staffCourierId "
            + "AND o.status = com.openbag.enums.OrderStatus.DELIVERED AND o.settlement IS NULL")
    List<Order> findUnsettledForStaffForUpdate(@Param("restaurantId") Long restaurantId,
                                               @Param("staffCourierId") Long staffCourierId);

    // ============= Rotas =============

    /**
     * Lojas com pedidos esperando o planejador liberar a chamada do entregador
     */
    @Query("SELECT DISTINCT o.restaurant.id FROM Order o WHERE o.status IN :statuses AND o.deliveryPerson IS NULL "
            + "AND o.staffCourier IS NULL AND o.dispatchReleasedAt IS NULL " + NOT_PICKUP)
    List<Long> findRestaurantIdsAwaitingRelease(@Param("statuses") java.util.Collection<OrderStatus> statuses);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT o FROM Order o WHERE o.restaurant.id = :restaurantId AND o.status IN :statuses "
            + "AND o.deliveryPerson IS NULL AND o.staffCourier IS NULL AND o.dispatchReleasedAt IS NULL " + NOT_PICKUP
            + " ORDER BY o.id")
    List<Order> findAwaitingReleaseForUpdate(@Param("restaurantId") Long restaurantId,
                                            @Param("statuses") java.util.Collection<OrderStatus> statuses);

    /** Painel admin: todos os pedidos, com filtro opcional de status */
    Page<Order> findByStatus(OrderStatus status, Pageable pageable);

    long countByCreatedAtGreaterThanEqual(java.time.LocalDateTime start);
}
