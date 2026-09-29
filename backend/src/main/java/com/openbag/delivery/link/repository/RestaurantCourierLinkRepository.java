package com.openbag.delivery.link.repository;

import com.openbag.delivery.link.entity.CourierLinkStatus;
import com.openbag.delivery.link.entity.RestaurantCourierLink;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

@Repository
public interface RestaurantCourierLinkRepository extends JpaRepository<RestaurantCourierLink, Long> {

    @Query("SELECT l FROM RestaurantCourierLink l JOIN FETCH l.deliveryPerson dp JOIN FETCH dp.user "
            + "WHERE l.restaurant.id = :restaurantId AND l.status IN :statuses ORDER BY l.createdAt DESC")
    List<RestaurantCourierLink> findByRestaurant(@Param("restaurantId") Long restaurantId,
                                                 @Param("statuses") Collection<CourierLinkStatus> statuses);

    @Query("SELECT l FROM RestaurantCourierLink l JOIN FETCH l.restaurant "
            + "WHERE l.deliveryPerson.id = :deliveryPersonId AND l.status IN :statuses ORDER BY l.createdAt DESC")
    List<RestaurantCourierLink> findByCourier(@Param("deliveryPersonId") Long deliveryPersonId,
                                              @Param("statuses") Collection<CourierLinkStatus> statuses);

    @Query("SELECT l FROM RestaurantCourierLink l WHERE l.restaurant.id = :restaurantId "
            + "AND l.deliveryPerson.id = :deliveryPersonId AND l.status IN :statuses")
    Optional<RestaurantCourierLink> findOpen(@Param("restaurantId") Long restaurantId,
                                             @Param("deliveryPersonId") Long deliveryPersonId,
                                             @Param("statuses") Collection<CourierLinkStatus> statuses);

    Optional<RestaurantCourierLink> findByIdAndRestaurantId(Long id, Long restaurantId);

    Optional<RestaurantCourierLink> findByIdAndDeliveryPersonId(Long id, Long deliveryPersonId);

    boolean existsByRestaurantIdAndDeliveryPersonIdAndStatus(Long restaurantId, Long deliveryPersonId,
                                                             CourierLinkStatus status);
}
