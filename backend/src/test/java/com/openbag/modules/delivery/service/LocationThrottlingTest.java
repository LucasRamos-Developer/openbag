package com.openbag.modules.delivery.service;

import com.openbag.modules.delivery.dispatch.DispatchProperties;
import com.openbag.modules.delivery.dto.LocationRequest;
import com.openbag.modules.delivery.entity.DeliveryPerson;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;

class LocationThrottlingTest {

    private static final LocalDateTime NOW = LocalDateTime.of(2026, 9, 29, 12, 0);

    private CourierWorkService service;
    private DeliveryPerson courier;

    @BeforeEach
    void setUp() {
        DispatchProperties properties = new DispatchProperties();
        ReflectionTestUtils.setField(properties, "locationMinIntervalSeconds", 10);
        ReflectionTestUtils.setField(properties, "locationMaxSpeedKmh", 150.0);
        service = new CourierWorkService();
        ReflectionTestUtils.setField(service, "properties", properties);
        courier = new DeliveryPerson();
        courier.setLastLatitude(-26.9194);
        courier.setLastLongitude(-49.0661);
    }

    private static LocationRequest at(double latitude, double longitude) {
        LocationRequest location = new LocationRequest();
        location.setLatitude(latitude);
        location.setLongitude(longitude);
        return location;
    }

    @Test
    void theFirstPositionAlwaysCounts() {
        courier.setLastLatitude(null);
        assertThat(service.acceptsLocation(courier, at(-26.92, -49.07), NOW)).isTrue();
    }

    @Test
    void atMostOnePingEveryTenSeconds() {
        courier.setLastSeenAt(NOW.minusSeconds(4));
        assertThat(service.acceptsLocation(courier, at(-26.9195, -49.0662), NOW)).isFalse();

        courier.setLastSeenAt(NOW.minusSeconds(12));
        assertThat(service.acceptsLocation(courier, at(-26.9195, -49.0662), NOW)).isTrue();
    }

    @Test
    void anImpossibleJumpIsIgnoredButNotForever() {
        // ~11 km em 20 s (quase 2.000 km/h): GPS ruim
        courier.setLastSeenAt(NOW.minusSeconds(20));
        assertThat(service.acceptsLocation(courier, at(-26.82, -49.07), NOW)).isFalse();

        // Um minuto depois, a posição nova vale (o salto errado não prende o entregador)
        courier.setLastSeenAt(NOW.minusSeconds(70));
        assertThat(service.acceptsLocation(courier, at(-26.82, -49.07), NOW)).isTrue();
    }

    @Test
    void aMotorcycleInTrafficIsFine() {
        // ~500 m em 20 s = 90 km/h
        courier.setLastSeenAt(NOW.minusSeconds(20));
        assertThat(service.acceptsLocation(courier, at(-26.9194, -49.0611), NOW)).isTrue();
    }
}
