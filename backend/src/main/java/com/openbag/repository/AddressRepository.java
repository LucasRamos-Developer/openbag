package com.openbag.repository;

import com.openbag.entity.Address;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AddressRepository extends JpaRepository<Address, Long> {

    List<Address> findByUserId(Long userId);

    @Query("SELECT a FROM Address a WHERE a.zipCode = :zipCode")
    List<Address> findByZipCode(@Param("zipCode") String zipCode);

    @Query("SELECT a FROM Address a WHERE a.city LIKE %:city% AND a.state = :state")
    List<Address> findByCityAndState(@Param("city") String city, @Param("state") String state);

    @Query("SELECT a FROM Address a WHERE a.neighborhood LIKE %:neighborhood%")
    List<Address> findByNeighborhoodContaining(@Param("neighborhood") String neighborhood);
}
