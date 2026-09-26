package com.openbag.modules.restaurant.entity;

import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.time.LocalTime;

import static org.assertj.core.api.Assertions.assertThat;

class RestaurantOpenNowTest {

    // 2026-09-21 é uma segunda-feira (weekday 1)
    private static final LocalDateTime MONDAY_NOON = LocalDateTime.of(2026, 9, 21, 12, 0);

    private static OpeningHour hour(int weekday, String open, String close) {
        OpeningHour hour = new OpeningHour();
        hour.setWeekday(weekday);
        hour.setOpenTime(LocalTime.parse(open));
        hour.setCloseTime(LocalTime.parse(close));
        return hour;
    }

    private static Restaurant restaurantWith(OpeningHour... hours) {
        Restaurant restaurant = new Restaurant();
        restaurant.setActive(true);
        restaurant.setOpen(true);
        for (OpeningHour hour : hours) {
            hour.setRestaurant(restaurant);
            restaurant.getOpeningHours().add(hour);
        }
        return restaurant;
    }

    @Test
    void sameDayHourCoversOnlyItsInterval() {
        OpeningHour lunch = hour(1, "11:00", "15:00");
        assertThat(lunch.covers(MONDAY_NOON)).isTrue();
        assertThat(lunch.covers(MONDAY_NOON.withHour(15))).isFalse();
        assertThat(lunch.covers(MONDAY_NOON.withHour(10).withMinute(59))).isFalse();
        assertThat(lunch.covers(MONDAY_NOON.plusDays(1))).isFalse();
    }

    @Test
    void overnightHourContinuesIntoNextDay() {
        OpeningHour night = hour(1, "18:00", "02:00");
        assertThat(night.covers(MONDAY_NOON.withHour(23))).isTrue();
        // Terça 01:30 ainda pertence ao turno de segunda
        assertThat(night.covers(MONDAY_NOON.plusDays(1).withHour(1).withMinute(30))).isTrue();
        assertThat(night.covers(MONDAY_NOON.plusDays(1).withHour(2))).isFalse();
        assertThat(night.covers(MONDAY_NOON.withHour(17))).isFalse();
    }

    @Test
    void sundayOvernightWrapsToMonday() {
        OpeningHour sundayNight = hour(7, "20:00", "01:00");
        assertThat(sundayNight.covers(MONDAY_NOON.withHour(0).withMinute(30))).isTrue();
    }

    @Test
    void openNowRequiresActiveOpenNotPausedAndWithinHours() {
        Restaurant restaurant = restaurantWith(hour(1, "11:00", "15:00"));
        assertThat(restaurant.isOpenNow(MONDAY_NOON)).isTrue();
        assertThat(restaurant.isOpenNow(MONDAY_NOON.withHour(16))).isFalse();

        restaurant.setPausedUntil(MONDAY_NOON.plusMinutes(30));
        assertThat(restaurant.isOpenNow(MONDAY_NOON)).isFalse();
        assertThat(restaurant.isOpenNow(MONDAY_NOON.plusMinutes(31))).isTrue();

        restaurant.setPausedUntil(null);
        restaurant.setOpen(false);
        assertThat(restaurant.isOpenNow(MONDAY_NOON)).isFalse();
    }

    @Test
    void withoutHoursOnlyManualFlagCounts() {
        Restaurant restaurant = restaurantWith();
        assertThat(restaurant.isOpenNow(MONDAY_NOON)).isTrue();
        restaurant.setActive(false);
        assertThat(restaurant.isOpenNow(MONDAY_NOON)).isFalse();
    }
}
