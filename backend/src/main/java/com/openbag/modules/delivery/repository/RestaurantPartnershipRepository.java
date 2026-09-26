package com.openbag.modules.delivery.repository;

import com.openbag.modules.delivery.entity.RestaurantPartnership;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface RestaurantPartnershipRepository extends JpaRepository<RestaurantPartnership, Long> {

    @Query("SELECT p FROM RestaurantPartnership p JOIN FETCH p.organization "
            + "WHERE p.restaurant.id = :restaurantId AND p.endedAt IS NULL ORDER BY p.createdAt")
    List<RestaurantPartnership> findActiveByRestaurant(@Param("restaurantId") Long restaurantId);

    @Query("SELECT p FROM RestaurantPartnership p "
            + "WHERE p.restaurant.id = :restaurantId AND p.organization.id = :organizationId AND p.endedAt IS NULL")
    Optional<RestaurantPartnership> findActive(@Param("restaurantId") Long restaurantId,
                                               @Param("organizationId") Long organizationId);
}
