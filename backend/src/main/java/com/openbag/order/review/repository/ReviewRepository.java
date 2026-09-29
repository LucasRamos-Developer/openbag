package com.openbag.order.review.repository;

import com.openbag.order.review.entity.Review;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

@Repository
public interface ReviewRepository extends JpaRepository<Review, Long> {

    /** Média e quantidade de notas */
    interface RatingAggregate {
        Double getAverage();

        Long getCount();
    }

    boolean existsByOrderId(Long orderId);

    Optional<Review> findByOrderId(Long orderId);

    @Query("SELECT r FROM Review r WHERE r.order.id IN :orderIds")
    List<Review> findByOrderIds(@Param("orderIds") Collection<Long> orderIds);

    @EntityGraph(attributePaths = {"user", "order"})
    Page<Review> findByRestaurantIdOrderByCreatedAtDesc(Long restaurantId, Pageable pageable);

    Optional<Review> findByIdAndRestaurantId(Long id, Long restaurantId);

    @Query("SELECT AVG(r.restaurantRating) AS average, COUNT(r) AS count FROM Review r WHERE r.restaurant.id = :restaurantId")
    RatingAggregate aggregateRestaurant(@Param("restaurantId") Long restaurantId);

    @Query("SELECT AVG(r.courierRating) AS average, COUNT(r) AS count FROM Review r "
            + "WHERE r.deliveryPerson.id = :deliveryPersonId AND r.courierRating IS NOT NULL")
    RatingAggregate aggregateCourier(@Param("deliveryPersonId") Long deliveryPersonId);

    /** Quantidade de avaliações por nota da loja: [nota, quantidade] */
    @Query("SELECT r.restaurantRating, COUNT(r) FROM Review r WHERE r.restaurant.id = :restaurantId GROUP BY r.restaurantRating")
    List<Object[]> countByRestaurantRating(@Param("restaurantId") Long restaurantId);
}
