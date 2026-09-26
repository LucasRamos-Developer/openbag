package com.openbag.modules.delivery.repository;

import com.openbag.enums.DeliveryOfferStatus;
import com.openbag.modules.delivery.entity.DeliveryOffer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.Set;

@Repository
public interface DeliveryOfferRepository extends JpaRepository<DeliveryOffer, Long> {

    List<DeliveryOffer> findByOrderIdAndStatus(Long orderId, DeliveryOfferStatus status);

    boolean existsByOrderIdAndStatus(Long orderId, DeliveryOfferStatus status);

    boolean existsByDeliveryPersonIdAndStatus(Long deliveryPersonId, DeliveryOfferStatus status);

    @Query("SELECT o FROM DeliveryOffer o JOIN FETCH o.order WHERE o.deliveryPerson.id = :deliveryPersonId "
            + "AND o.status = com.openbag.enums.DeliveryOfferStatus.PENDING")
    Optional<DeliveryOffer> findPendingByCourier(@Param("deliveryPersonId") Long deliveryPersonId);

    Optional<DeliveryOffer> findByIdAndDeliveryPersonId(Long id, Long deliveryPersonId);

    @Query("SELECT o FROM DeliveryOffer o WHERE o.status = com.openbag.enums.DeliveryOfferStatus.PENDING "
            + "AND o.expiresAt < :now")
    List<DeliveryOffer> findExpired(@Param("now") LocalDateTime now);

    /**
     * Entregadores que já receberam este pedido (recusaram, deixaram expirar ou estão com a oferta)
     */
    @Query("SELECT DISTINCT o.deliveryPerson.id FROM DeliveryOffer o WHERE o.order.id = :orderId")
    Set<Long> findOfferedCourierIds(@Param("orderId") Long orderId);

    /**
     * Entregadores com oferta pendente (não recebem outra ao mesmo tempo)
     */
    @Query("SELECT o.deliveryPerson.id FROM DeliveryOffer o WHERE o.status = com.openbag.enums.DeliveryOfferStatus.PENDING")
    Set<Long> findCourierIdsWithPendingOffer();
}
