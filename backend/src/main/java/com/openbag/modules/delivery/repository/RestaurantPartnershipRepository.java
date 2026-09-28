package com.openbag.modules.delivery.repository;

import com.openbag.modules.delivery.entity.RestaurantPartnership;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

@Repository
public interface RestaurantPartnershipRepository extends JpaRepository<RestaurantPartnership, Long> {

    // Parcerias anteriores ao aceite têm status nulo e valem enquanto não forem encerradas
    String ACTIVE = "(p.status = com.openbag.enums.PartnershipStatus.ACTIVE OR (p.status IS NULL AND p.endedAt IS NULL))";
    String OPEN = "(p.status = com.openbag.enums.PartnershipStatus.PENDING OR " + ACTIVE + ")";

    @Query("SELECT p FROM RestaurantPartnership p JOIN FETCH p.organization "
            + "WHERE p.restaurant.id = :restaurantId AND " + ACTIVE + " ORDER BY p.createdAt")
    List<RestaurantPartnership> findActiveByRestaurant(@Param("restaurantId") Long restaurantId);

    /** Parcerias ativas de várias lojas de uma vez (taxa "a partir de" na vitrine) */
    @Query("SELECT p FROM RestaurantPartnership p JOIN FETCH p.organization "
            + "WHERE p.restaurant.id IN :restaurantIds AND " + ACTIVE)
    List<RestaurantPartnership> findActiveByRestaurantIds(@Param("restaurantIds") Collection<Long> restaurantIds);

    @Query("SELECT p FROM RestaurantPartnership p "
            + "WHERE p.restaurant.id = :restaurantId AND p.organization.id = :organizationId AND " + ACTIVE)
    Optional<RestaurantPartnership> findActive(@Param("restaurantId") Long restaurantId,
                                               @Param("organizationId") Long organizationId);

    /** Pedido pendente ou parceria ativa: só uma por par loja/associação */
    @Query("SELECT p FROM RestaurantPartnership p "
            + "WHERE p.restaurant.id = :restaurantId AND p.organization.id = :organizationId AND " + OPEN)
    Optional<RestaurantPartnership> findOpen(@Param("restaurantId") Long restaurantId,
                                             @Param("organizationId") Long organizationId);

    /** Todas as parcerias da loja (pendentes, ativas e histórico), mais recentes primeiro */
    @Query("SELECT p FROM RestaurantPartnership p JOIN FETCH p.organization "
            + "WHERE p.restaurant.id = :restaurantId ORDER BY p.createdAt DESC")
    List<RestaurantPartnership> findByRestaurant(@Param("restaurantId") Long restaurantId);

    /** Todas as parcerias da associação (pendentes, ativas e histórico), mais recentes primeiro */
    @Query("SELECT p FROM RestaurantPartnership p JOIN FETCH p.restaurant r LEFT JOIN FETCH r.address "
            + "WHERE p.organization.id = :organizationId ORDER BY p.createdAt DESC")
    List<RestaurantPartnership> findByOrganization(@Param("organizationId") Long organizationId);

    @Query("SELECT p FROM RestaurantPartnership p JOIN FETCH p.restaurant JOIN FETCH p.organization "
            + "WHERE p.id = :id")
    Optional<RestaurantPartnership> findWithParties(@Param("id") Long id);

    /** Restaurantes com parceria ativa com a associação (para marcar acordo nos relatórios) */
    @Query("SELECT p FROM RestaurantPartnership p WHERE p.organization.id = :organizationId AND " + ACTIVE)
    List<RestaurantPartnership> findActiveByOrganization(@Param("organizationId") Long organizationId);

    @Modifying
    @Query("UPDATE RestaurantPartnership p SET p.status = com.openbag.enums.PartnershipStatus.ACTIVE "
            + "WHERE p.status IS NULL AND p.endedAt IS NULL")
    int backfillActiveStatus();

    @Modifying
    @Query("UPDATE RestaurantPartnership p SET p.status = com.openbag.enums.PartnershipStatus.ENDED "
            + "WHERE p.status IS NULL AND p.endedAt IS NOT NULL")
    int backfillEndedStatus();
}
