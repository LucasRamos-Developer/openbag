package com.openbag.order.incident.repository;

import com.openbag.order.incident.entity.IncidentType;
import com.openbag.order.incident.entity.OrderIncident;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface OrderIncidentRepository extends JpaRepository<OrderIncident, Long> {

    boolean existsByOrderIdAndDeliveryPersonIdAndType(Long orderId, Long deliveryPersonId, IncidentType type);

    /** Uma linha por loja e tipo */
    record RestaurantTypeCount(Long restaurantId, String name, String slug, String logoUrl, IncidentType type,
                               long count) {
    }

    /** Ocorrências relatadas pelos cooperados da associação no período, por loja e por tipo */
    @Query("SELECT new com.openbag.order.incident.repository.OrderIncidentRepository$RestaurantTypeCount("
            + "r.id, r.name, r.slug, r.logoUrl, i.type, COUNT(i)) "
            + "FROM OrderIncident i JOIN i.restaurant r "
            + "WHERE i.organization.id = :organizationId AND i.createdAt >= :start AND i.createdAt < :end "
            + "GROUP BY r.id, r.name, r.slug, r.logoUrl, i.type")
    List<RestaurantTypeCount> countByRestaurantAndType(@Param("organizationId") Long organizationId,
                                                       @Param("start") LocalDateTime start,
                                                       @Param("end") LocalDateTime end);
}
