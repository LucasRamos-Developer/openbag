package com.openbag.modules.user.repository;

import com.openbag.modules.user.entity.Address;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AddressRepository extends JpaRepository<Address, Long> {

    List<Address> findByUserId(Long userId);
    
    Optional<Address> findByIdAndUserId(Long id, Long userId);

    @Query("SELECT a FROM Address a WHERE a.zipCode = :zipCode")
    List<Address> findByZipCode(@Param("zipCode") String zipCode);

    @Query("SELECT a FROM Address a WHERE a.city LIKE %:city% AND a.state = :state")
    List<Address> findByCityAndState(@Param("city") String city, @Param("state") String state);

    @Query("SELECT a FROM Address a WHERE a.neighborhood LIKE %:neighborhood%")
    List<Address> findByNeighborhoodContaining(@Param("neighborhood") String neighborhood);
}
