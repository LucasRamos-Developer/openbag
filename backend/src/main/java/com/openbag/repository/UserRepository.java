package com.openbag.repository;

import com.openbag.entity.User;
import com.openbag.enums.UserType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByEmail(String email);
    
    Optional<User> findByPhoneNumber(String phoneNumber);
    
    boolean existsByEmail(String email);
    
    boolean existsByPhoneNumber(String phoneNumber);
    
    @Query("SELECT u FROM User u WHERE u.userType = :userType AND u.isActive = true")
    List<User> findByUserTypeAndActive(@Param("userType") UserType userType);
    
    @Query("SELECT u FROM User u WHERE u.userType = 'DELIVERY_PERSON' AND u.isActive = true")
    List<User> findAvailableDeliveryPersons();
}
