package com.openbag.modules.product.repository;

import com.openbag.modules.product.entity.OrderItemCustomization;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;

@Repository
public interface OrderItemCustomizationRepository extends JpaRepository<OrderItemCustomization, Long> {

    boolean existsByCustomizationOptionIdIn(Collection<Long> optionIds);

    @Query("SELECT COUNT(c) > 0 FROM OrderItemCustomization c WHERE c.customizationOption.customizationGroup.id = :groupId")
    boolean existsByGroupId(@Param("groupId") Long groupId);
}
