package com.openbag.modules.restaurant.entity;

import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.time.LocalTime;

import static org.assertj.core.api.Assertions.assertThat;

/** Quando fecha e quando abre: textos "fecha às" / "abre às" da vitrine */
class RestaurantScheduleTest {

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
    void openRestaurantClosesAtTheEndOfTheCurrentShift() {
        Restaurant restaurant = restaurantWith(hour(1, "11:00", "15:00"), hour(1, "18:00", "23:00"));

        assertThat(restaurant.closesAt(MONDAY_NOON)).isEqualTo(MONDAY_NOON.withHour(15));
        assertThat(restaurant.nextOpeningAt(MONDAY_NOON)).isNull();
    }

    @Test
    void backToBackShiftsCountAsOne() {
        Restaurant restaurant = restaurantWith(hour(1, "11:00", "15:00"), hour(1, "15:00", "23:00"));

        assertThat(restaurant.closesAt(MONDAY_NOON)).isEqualTo(MONDAY_NOON.withHour(23));
    }

    @Test
    void closedBetweenShiftsOpensLaterToday() {
        Restaurant restaurant = restaurantWith(hour(1, "11:00", "15:00"), hour(1, "18:00", "23:00"));
        LocalDateTime afternoon = MONDAY_NOON.withHour(16);

        assertThat(restaurant.closesAt(afternoon)).isNull();
        assertThat(restaurant.nextOpeningAt(afternoon)).isEqualTo(MONDAY_NOON.withHour(18));
    }

    @Test
    void closedTodayOpensOnTheNextWorkingDay() {
        // Só quarta-feira
        Restaurant restaurant = restaurantWith(hour(3, "11:00", "15:00"));

        assertThat(restaurant.nextOpeningAt(MONDAY_NOON)).isEqualTo(MONDAY_NOON.plusDays(2).withHour(11));
    }

    @Test
    void afterTheLastShiftOfTheWeekWrapsToNextWeek() {
        // Só segunda de manhã: ao meio-dia, a próxima é a segunda seguinte
        Restaurant restaurant = restaurantWith(hour(1, "08:00", "11:00"));

        assertThat(restaurant.nextOpeningAt(MONDAY_NOON)).isEqualTo(MONDAY_NOON.plusDays(7).withHour(8));
    }

    @Test
    void overnightShiftClosesNextDay() {
        Restaurant restaurant = restaurantWith(hour(1, "18:00", "02:00"));
        LocalDateTime lateMonday = MONDAY_NOON.withHour(23);
        LocalDateTime earlyTuesday = MONDAY_NOON.plusDays(1).withHour(1);

        assertThat(restaurant.closesAt(lateMonday)).isEqualTo(MONDAY_NOON.plusDays(1).withHour(2));
        assertThat(restaurant.closesAt(earlyTuesday)).isEqualTo(MONDAY_NOON.plusDays(1).withHour(2));
    }

    @Test
    void pausedOpensWhenThePauseEndsIfStillInsideTheShift() {
        Restaurant restaurant = restaurantWith(hour(1, "11:00", "23:00"));
        restaurant.setPausedUntil(MONDAY_NOON.plusMinutes(30));

        assertThat(restaurant.closesAt(MONDAY_NOON)).isNull();
        assertThat(restaurant.nextOpeningAt(MONDAY_NOON)).isEqualTo(MONDAY_NOON.plusMinutes(30));
    }

    @Test
    void manuallyClosedOrWithoutHoursHasNoForecast() {
        Restaurant closed = restaurantWith(hour(1, "11:00", "23:00"));
        closed.setOpen(false);
        Restaurant noHours = restaurantWith();

        assertThat(closed.nextOpeningAt(MONDAY_NOON)).isNull();
        assertThat(noHours.closesAt(MONDAY_NOON)).isNull();
        assertThat(noHours.nextOpeningAt(MONDAY_NOON)).isNull();
    }
}
