package com.openbag.association.core.repository;

import com.openbag.association.core.entity.AssociationInvite;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AssociationInviteRepository extends JpaRepository<AssociationInvite, Long> {

    Optional<AssociationInvite> findByCode(String code);

    /**
     * Busca o convite com lock pessimista, para que usos concorrentes respeitem o limite (maxUses)
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT i FROM AssociationInvite i WHERE i.code = :code")
    Optional<AssociationInvite> findByCodeForUpdate(@Param("code") String code);

    Optional<AssociationInvite> findByIdAndOrganizationId(Long id, Long organizationId);

    List<AssociationInvite> findByOrganizationIdOrderByCreatedAtDesc(Long organizationId);

    boolean existsByCode(String code);
}
