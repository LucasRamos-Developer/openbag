package com.openbag.repository;

import com.openbag.entity.OpeningHour;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OpeningHourRepository extends JpaRepository<OpeningHour, Long> {

    List<OpeningHour> findByRestaurantIdOrderByWeekdayAsc(Long restaurantId);
}
