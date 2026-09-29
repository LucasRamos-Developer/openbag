package com.openbag.association.finance.repository;

import com.openbag.enums.LedgerAccount;
import com.openbag.association.finance.entity.LedgerEntry;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface LedgerEntryRepository extends JpaRepository<LedgerEntry, Long> {

    @Query(value = "SELECT e FROM LedgerEntry e LEFT JOIN FETCH e.membership m LEFT JOIN FETCH m.deliveryPerson dp "
            + "LEFT JOIN FETCH dp.user WHERE e.organization.id = :organizationId "
            + "AND (:anyAccount = true OR e.account = :account) AND e.date >= :from AND e.date <= :to",
            countQuery = "SELECT COUNT(e) FROM LedgerEntry e WHERE e.organization.id = :organizationId "
                    + "AND (:anyAccount = true OR e.account = :account) AND e.date >= :from AND e.date <= :to")
    Page<LedgerEntry> search(@Param("organizationId") Long organizationId, @Param("anyAccount") boolean anyAccount,
                             @Param("account") LedgerAccount account, @Param("from") LocalDate from,
                             @Param("to") LocalDate to, Pageable pageable);

    /** Lançamentos do período, para o painel financeiro */
    @Query("SELECT e FROM LedgerEntry e WHERE e.organization.id = :organizationId AND e.date >= :from AND e.date <= :to")
    List<LedgerEntry> findBetween(@Param("organizationId") Long organizationId, @Param("from") LocalDate from,
                                  @Param("to") LocalDate to);

    /** Saldo de uma conta desde o início (entradas menos saídas) */
    @Query("SELECT COALESCE(SUM(CASE WHEN e.direction = com.openbag.enums.LedgerDirection.IN THEN e.amount "
            + "ELSE -e.amount END), 0) FROM LedgerEntry e WHERE e.organization.id = :organizationId AND e.account = :account")
    BigDecimal balance(@Param("organizationId") Long organizationId, @Param("account") LedgerAccount account);

    /** Quanto o cooperado já deu à caixinha */
    @Query("SELECT COALESCE(SUM(e.amount), 0) FROM LedgerEntry e WHERE e.membership.id = :membershipId "
            + "AND e.account = com.openbag.enums.LedgerAccount.SOLIDARITY_FUND "
            + "AND e.direction = com.openbag.enums.LedgerDirection.IN")
    BigDecimal contributedBy(@Param("membershipId") Long membershipId);

    /** Movimentações de uma conta, mais recentes primeiro */
    @Query("SELECT e FROM LedgerEntry e WHERE e.organization.id = :organizationId AND e.account = :account "
            + "ORDER BY e.date DESC, e.id DESC")
    List<LedgerEntry> findRecent(@Param("organizationId") Long organizationId, @Param("account") LedgerAccount account,
                                 Pageable pageable);

    Optional<LedgerEntry> findByIdAndOrganizationId(Long id, Long organizationId);

    @Modifying
    @Query("DELETE FROM LedgerEntry e WHERE e.invoice.id = :invoiceId")
    int deleteByInvoice(@Param("invoiceId") Long invoiceId);
}
