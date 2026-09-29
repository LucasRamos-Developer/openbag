package com.openbag.association.core.repository;

import com.openbag.enums.MembershipStatus;
import com.openbag.enums.VehicleType;
import com.openbag.association.core.entity.AssociationMembership;
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

    /** Todos os vínculos da associação, inclusive histórico (número de associado nos relatórios) */
    List<AssociationMembership> findByOrganizationId(Long organizationId);

    /**
     * Busca paginada dos associados de uma organização.
     * {@code q} vazio desativa a busca textual (nome, email ou CPF), {@code anyVehicle} desativa o filtro pelo
     * veículo em uso e {@code billing} filtra pela mensalidade: ALL, OPEN (com fatura em aberto) ou UP_TO_DATE.
     */
    @Query(value = """
            SELECT m FROM AssociationMembership m
            JOIN FETCH m.deliveryPerson dp
            JOIN FETCH dp.user u
            WHERE m.organization.id = :organizationId
              AND m.status IN :statuses
              AND (:anyVehicle = true OR dp.vehicleType = :vehicleType)
              AND (:billing = 'ALL'
                   OR (:billing = 'OPEN' AND EXISTS (SELECT i.id FROM MemberInvoice i WHERE i.membership = m
                           AND i.status = com.openbag.enums.InvoiceStatus.OPEN))
                   OR (:billing = 'UP_TO_DATE' AND NOT EXISTS (SELECT i.id FROM MemberInvoice i WHERE i.membership = m
                           AND i.status = com.openbag.enums.InvoiceStatus.OPEN)))
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
              AND (:anyVehicle = true OR dp.vehicleType = :vehicleType)
              AND (:billing = 'ALL'
                   OR (:billing = 'OPEN' AND EXISTS (SELECT i.id FROM MemberInvoice i WHERE i.membership = m
                           AND i.status = com.openbag.enums.InvoiceStatus.OPEN))
                   OR (:billing = 'UP_TO_DATE' AND NOT EXISTS (SELECT i.id FROM MemberInvoice i WHERE i.membership = m
                           AND i.status = com.openbag.enums.InvoiceStatus.OPEN)))
              AND (:q = '' OR LOWER(u.fullName) LIKE LOWER(CONCAT('%', :q, '%'))
                           OR LOWER(u.email) LIKE LOWER(CONCAT('%', :q, '%'))
                           OR dp.documentNumber LIKE CONCAT('%', :q, '%'))
            """)
    Page<AssociationMembership> search(@Param("organizationId") Long organizationId,
                                       @Param("statuses") Collection<MembershipStatus> statuses,
                                       @Param("anyVehicle") boolean anyVehicle,
                                       @Param("vehicleType") VehicleType vehicleType,
                                       @Param("billing") String billing,
                                       @Param("q") String q,
                                       Pageable pageable);

    /** Faturas em aberto por associado: [membershipId, quantidade, total] */
    @Query("SELECT i.membership.id, COUNT(i), COALESCE(SUM(i.total), 0) FROM MemberInvoice i "
            + "WHERE i.organization.id = :organizationId AND i.status = com.openbag.enums.InvoiceStatus.OPEN "
            + "GROUP BY i.membership.id")
    List<Object[]> openInvoicesByMembership(@Param("organizationId") Long organizationId);

    /** Adicionais ativos por associado: [membershipId, nome do adicional] */
    @Query("SELECT a.membership.id, a.plan.name FROM MemberAddon a WHERE a.membership.organization.id = :organizationId "
            + "AND a.status = com.openbag.enums.MemberAddonStatus.ACTIVE")
    List<Object[]> activeAddonNames(@Param("organizationId") Long organizationId);

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
