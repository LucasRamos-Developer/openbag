package com.openbag.modules.organization.repository;

import com.openbag.enums.MembershipStatus;
import com.openbag.modules.organization.entity.AssociationMembership;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

@Repository
public interface AssociationMembershipRepository extends JpaRepository<AssociationMembership, Long> {

    Optional<AssociationMembership> findByIdAndOrganizationId(Long id, Long organizationId);

    List<AssociationMembership> findByDeliveryPersonIdAndStatusIn(Long deliveryPersonId, Collection<MembershipStatus> statuses);

    /**
     * Busca paginada dos associados de uma organização.
     * {@code q} vazio desativa a busca textual (nome, email ou CPF).
     */
    @Query(value = """
            SELECT m FROM AssociationMembership m
            JOIN FETCH m.deliveryPerson dp
            JOIN FETCH dp.user u
            WHERE m.organization.id = :organizationId
              AND m.status IN :statuses
              AND (:q = '' OR LOWER(u.fullName) LIKE LOWER(CONCAT('%', :q, '%'))
                           OR LOWER(u.email) LIKE LOWER(CONCAT('%', :q, '%'))
                           OR dp.documentNumber LIKE CONCAT('%', :q, '%'))
            """,
            countQuery = """
            SELECT COUNT(m) FROM AssociationMembership m
            JOIN m.deliveryPerson dp
            JOIN dp.user u
            WHERE m.organization.id = :organizationId
              AND m.status IN :statuses
              AND (:q = '' OR LOWER(u.fullName) LIKE LOWER(CONCAT('%', :q, '%'))
                           OR LOWER(u.email) LIKE LOWER(CONCAT('%', :q, '%'))
                           OR dp.documentNumber LIKE CONCAT('%', :q, '%'))
            """)
    Page<AssociationMembership> search(@Param("organizationId") Long organizationId,
                                       @Param("statuses") Collection<MembershipStatus> statuses,
                                       @Param("q") String q,
                                       Pageable pageable);

    @Query("SELECT COALESCE(MAX(m.memberNumber), 0) FROM AssociationMembership m WHERE m.organization.id = :organizationId")
    int findMaxMemberNumber(@Param("organizationId") Long organizationId);

    @Query("SELECT m.status, COUNT(m) FROM AssociationMembership m WHERE m.organization.id = :organizationId GROUP BY m.status")
    List<Object[]> countByStatus(@Param("organizationId") Long organizationId);

    @Query("""
            SELECT m.deliveryPerson.vehicleType, COUNT(m) FROM AssociationMembership m
            WHERE m.organization.id = :organizationId AND m.status = com.openbag.enums.MembershipStatus.ACTIVE
            GROUP BY m.deliveryPerson.vehicleType
            """)
    List<Object[]> countActiveByVehicleType(@Param("organizationId") Long organizationId);

    @Query("""
            SELECT COUNT(m) FROM AssociationMembership m
            WHERE m.organization.id = :organizationId AND m.status = com.openbag.enums.MembershipStatus.ACTIVE
              AND m.deliveryPerson.isAvailable = true
            """)
    long countAvailableNow(@Param("organizationId") Long organizationId);

    @Query("""
            SELECT COALESCE(SUM(m.deliveryPerson.totalDeliveries), 0) FROM AssociationMembership m
            WHERE m.organization.id = :organizationId AND m.status = com.openbag.enums.MembershipStatus.ACTIVE
            """)
    long sumActiveDeliveries(@Param("organizationId") Long organizationId);
}
