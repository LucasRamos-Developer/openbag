package com.openbag.modules.shared.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

import static org.assertj.core.api.Assertions.assertThat;

class GeocodingQueueTest {

    @Test
    void aFloodOfAddressesDoesNotHoldThreadsWaitingInLine() throws Exception {
        GeocodingService service = new GeocodingService(new ObjectMapper(), "http://localhost:1", true);
        ExecutorService pool = Executors.newFixedThreadPool(8);
        List<Callable<Boolean>> calls = new ArrayList<>();
        for (int i = 0; i < 8; i++) {
            calls.add(service::waitForTurn);
        }

        long start = System.nanoTime();
        List<Boolean> turns = new ArrayList<>();
        for (Future<Boolean> turn : pool.invokeAll(calls)) {
            turns.add(turn.get());
        }
        long seconds = (System.nanoTime() - start) / 1_000_000_000L;
        pool.shutdown();

        // 1 consulta por segundo e no máximo 3 s de espera: 3 conseguem vaga e as outras desistem na hora
        assertThat(turns.stream().filter(Boolean::booleanValue)).hasSize(3);
        assertThat(seconds).isLessThanOrEqualTo(3);
    }
}
