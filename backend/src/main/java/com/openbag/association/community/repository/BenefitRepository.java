package com.openbag.association.community.repository;

import com.openbag.association.community.entity.Benefit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface BenefitRepository extends JpaRepository<Benefit, Long> {

    List<Benefit> findByOrganizationIdOrderByPartnerNameAsc(Long organizationId);

    Optional<Benefit> findByIdAndOrganizationId(Long id, Long organizationId);
}
