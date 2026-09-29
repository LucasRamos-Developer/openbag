package com.openbag.account.repository;

import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Page;
import com.openbag.account.entity.User;
import com.openbag.account.entity.UserType;
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

    @Query("SELECT COUNT(u) > 0 FROM User u JOIN u.roles r WHERE r.name = :roleName")
    boolean existsByRoleName(@Param("roleName") String roleName);
    
    @Query("SELECT u FROM User u WHERE u.userType = :userType AND u.isActive = true")
    List<User> findByUserTypeAndActive(@Param("userType") UserType userType);
    
    @Query("SELECT u FROM User u WHERE u.userType = 'DELIVERY_PERSON' AND u.isActive = true")
    List<User> findAvailableDeliveryPersons();

    /** Painel admin: busca por nome ou e-mail ([q] já em minúsculas com %) */
    @Query("select u from User u where lower(u.fullName) like :q or lower(u.email) like :q")
    Page<User> searchForAdmin(@Param("q") String q, Pageable pageable);
}
