package com.openbag.association.finance.repository;

import com.openbag.association.finance.entity.MemberAddonStatus;
import com.openbag.association.finance.entity.MemberAddon;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

@Repository
public interface MemberAddonRepository extends JpaRepository<MemberAddon, Long> {

    @Query("SELECT a FROM MemberAddon a JOIN FETCH a.plan WHERE a.membership.id = :membershipId ORDER BY a.proposedAt DESC")
    List<MemberAddon> findByMembership(@Param("membershipId") Long membershipId);

    @Query("SELECT a FROM MemberAddon a JOIN FETCH a.plan JOIN FETCH a.membership m "
            + "WHERE m.organization.id = :organizationId AND a.status IN :statuses")
    List<MemberAddon> findByOrganizationAndStatusIn(@Param("organizationId") Long organizationId,
                                                    @Param("statuses") Collection<MemberAddonStatus> statuses);

    @Query("SELECT a FROM MemberAddon a JOIN FETCH a.plan JOIN FETCH a.membership m "
            + "WHERE a.id = :id AND m.organization.id = :organizationId")
    Optional<MemberAddon> findByIdAndOrganization(@Param("id") Long id, @Param("organizationId") Long organizationId);

    /** Proposto ou ativo: um por cooperado e por plano */
    @Query("SELECT COUNT(a) > 0 FROM MemberAddon a WHERE a.membership.id = :membershipId AND a.plan.id = :planId "
            + "AND a.status IN (com.openbag.association.finance.entity.MemberAddonStatus.PROPOSED, com.openbag.association.finance.entity.MemberAddonStatus.ACTIVE)")
    boolean existsOpen(@Param("membershipId") Long membershipId, @Param("planId") Long planId);
}
