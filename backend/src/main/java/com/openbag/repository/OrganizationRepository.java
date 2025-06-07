package com.openbag.repository;

import com.openbag.entity.Organization;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface OrganizationRepository extends JpaRepository<Organization, Long> {

    Optional<Organization> findByCnpj(String cnpj);

    List<Organization> findByIsActiveTrue();

    @Query("SELECT o FROM Organization o WHERE o.companyName LIKE %:name% OR o.tradingName LIKE %:name%")
    List<Organization> findByNameContaining(@Param("name") String name);

    @Query("SELECT o FROM Organization o WHERE o.adminUser.id = :adminUserId")
    List<Organization> findByAdminUserId(@Param("adminUserId") Long adminUserId);

    boolean existsByCnpj(String cnpj);
}
