package com.openbag.association.core.repository;

import com.openbag.enums.OrganizationStatus;
import com.openbag.association.core.entity.Organization;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface OrganizationRepository extends JpaRepository<Organization, Long> {

    /** Serializa as saídas da caixinha e do caixa de uma associação (o saldo é conferido antes de gravar) */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT o FROM Organization o WHERE o.id = :id")
    Optional<Organization> findByIdForUpdate(@Param("id") Long id);

    Optional<Organization> findByCnpj(String cnpj);

    List<Organization> findByIsActiveTrue();

    @Query("SELECT o FROM Organization o WHERE o.companyName LIKE %:name% OR o.tradingName LIKE %:name%")
    List<Organization> findByNameContaining(@Param("name") String name);

    @Query("SELECT o FROM Organization o WHERE o.adminUser.id = :adminUserId")
    List<Organization> findByAdminUserId(@Param("adminUserId") Long adminUserId);

    boolean existsByCnpj(String cnpj);

    Page<Organization> findByStatus(OrganizationStatus status, Pageable pageable);

    List<Organization> findByStatusOrderByTradingNameAsc(OrganizationStatus status);

    long countByStatus(OrganizationStatus status);
}
