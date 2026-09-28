package com.openbag.modules.cooperative.repository;

import com.openbag.modules.cooperative.entity.AddonPlan;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AddonPlanRepository extends JpaRepository<AddonPlan, Long> {

    List<AddonPlan> findByOrganizationIdOrderByNameAsc(Long organizationId);

    Optional<AddonPlan> findByIdAndOrganizationId(Long id, Long organizationId);
}
