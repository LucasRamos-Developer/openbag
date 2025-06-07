package com.openbag.repository;

import com.openbag.entity.DeliveryPerson;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DeliveryPersonRepository extends JpaRepository<DeliveryPerson, Long> {

    Optional<DeliveryPerson> findByUserId(Long userId);

    Optional<DeliveryPerson> findByDocumentNumber(String documentNumber);

    Optional<DeliveryPerson> findByDriverLicense(String driverLicense);

    List<DeliveryPerson> findByIsActiveTrue();

    List<DeliveryPerson> findByIsAvailableTrue();

    @Query("SELECT dp FROM DeliveryPerson dp WHERE dp.isActive = true AND dp.isAvailable = true")
    List<DeliveryPerson> findAvailableDeliveryPersons();

    @Query("SELECT dp FROM DeliveryPerson dp WHERE dp.organization.id = :organizationId")
    List<DeliveryPerson> findByOrganizationId(@Param("organizationId") Long organizationId);

    @Query("SELECT dp FROM DeliveryPerson dp WHERE dp.organization IS NULL AND dp.isActive = true")
    List<DeliveryPerson> findIndependentDeliveryPersons();

    boolean existsByDocumentNumber(String documentNumber);

    boolean existsByDriverLicense(String driverLicense);
}
