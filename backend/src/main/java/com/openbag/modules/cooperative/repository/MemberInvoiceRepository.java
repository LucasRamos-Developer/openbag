package com.openbag.modules.cooperative.repository;

import com.openbag.enums.InvoiceStatus;
import com.openbag.modules.cooperative.entity.MemberInvoice;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface MemberInvoiceRepository extends JpaRepository<MemberInvoice, Long> {

    @Query("SELECT DISTINCT i FROM MemberInvoice i JOIN FETCH i.membership m JOIN FETCH m.deliveryPerson dp "
            + "JOIN FETCH dp.user LEFT JOIN FETCH i.lines "
            + "WHERE i.organization.id = :organizationId AND i.month = :month")
    List<MemberInvoice> findByOrganizationAndMonth(@Param("organizationId") Long organizationId,
                                                   @Param("month") LocalDate month);

    @Query("SELECT DISTINCT i FROM MemberInvoice i LEFT JOIN FETCH i.lines "
            + "WHERE i.membership.id = :membershipId ORDER BY i.month DESC")
    List<MemberInvoice> findByMembership(@Param("membershipId") Long membershipId);

    @Query("SELECT i FROM MemberInvoice i JOIN FETCH i.membership m JOIN FETCH m.deliveryPerson dp JOIN FETCH dp.user "
            + "WHERE i.id = :id AND i.organization.id = :organizationId")
    Optional<MemberInvoice> findByIdAndOrganization(@Param("id") Long id, @Param("organizationId") Long organizationId);

    /** Trava só a fatura (sem juntar o cooperado): duas baixas ao mesmo tempo esperam uma pela outra */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT i FROM MemberInvoice i WHERE i.id = :id AND i.organization.id = :organizationId")
    Optional<MemberInvoice> findByIdAndOrganizationForUpdate(@Param("id") Long id,
                                                             @Param("organizationId") Long organizationId);

    boolean existsByMembershipIdAndMonth(Long membershipId, LocalDate month);

    /** Total a receber: faturas em aberto da associação */
    @Query("SELECT COALESCE(SUM(i.total), 0) FROM MemberInvoice i "
            + "WHERE i.organization.id = :organizationId AND i.status = :status")
    BigDecimal sumByStatus(@Param("organizationId") Long organizationId, @Param("status") InvoiceStatus status);

    /** Em atraso: faturas em aberto que já venceram */
    @Query("SELECT COALESCE(SUM(i.total), 0) FROM MemberInvoice i WHERE i.organization.id = :organizationId "
            + "AND i.status = com.openbag.enums.InvoiceStatus.OPEN AND i.dueDate < :today")
    BigDecimal sumOverdue(@Param("organizationId") Long organizationId, @Param("today") LocalDate today);

    /** Cooperados com fatura em aberto (e quanto devem), para a lista e a exportação */
    @Query("SELECT i.membership.id, COUNT(i), COALESCE(SUM(i.total), 0) FROM MemberInvoice i "
            + "WHERE i.organization.id = :organizationId AND i.status = com.openbag.enums.InvoiceStatus.OPEN "
            + "GROUP BY i.membership.id")
    List<Object[]> openByMembership(@Param("organizationId") Long organizationId);
}
