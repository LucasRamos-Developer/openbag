package com.openbag.modules.shared.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class GeocodingServiceTest {

    private final GeocodingService service = new GeocodingService(new ObjectMapper(), "http://localhost:1", false);

    @Test
    void readsTheFirstResultOfTheNominatimSearch() throws Exception {
        var result = service.parse("[{\"lat\":\"-23.5505\",\"lon\":\"-46.6333\",\"display_name\":\"Sé\"}]");

        assertThat(result).contains(new GeocodingService.Coordinates(-23.5505, -46.6333));
    }

    @Test
    void emptySearchMeansTheAddressWasNotFound() throws Exception {
        assertThat(service.parse("[]")).isEmpty();
    }

    @Test
    void disabledServiceNeverCallsTheServer() {
        var address = new GeocodingService.AddressQuery("Rua A", "10", "Centro", "São Paulo", "SP", "01001000");

        assertThat(service.locate(address)).isEmpty();
    }
}
