package com.openbag.support;

import com.openbag.platform.web.idempotency.IdempotencyStore;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Os jobs com @SchedulerLock rodam em uma instância por vez: a trava fica na tabela shedlock, e uma segunda
 * execução dentro do intervalo mínimo (outra instância, no mesmo minuto) não faz nada
 */
class JobLockTest extends IntegrationTest {

    @Autowired private IdempotencyStore idempotencyStore;
    @Autowired private JdbcTemplate jdbc;

    @Test
    void aLockedJobRunsOncePerInterval() {
        jdbc.update("DELETE FROM shedlock WHERE name = 'idempotency.deleteExpired'");
        Long first = expiredKey();

        idempotencyStore.deleteExpired();

        assertThat(exists(first)).as("a primeira execução limpa").isFalse();
        assertThat(jdbc.queryForObject("SELECT count(*) FROM shedlock WHERE name = 'idempotency.deleteExpired' "
                + "AND lock_until > now()", Integer.class)).isEqualTo(1);

        Long second = expiredKey();
        idempotencyStore.deleteExpired();

        assertThat(exists(second)).as("dentro do intervalo mínimo, a trava segura a segunda execução").isTrue();
    }

    private Long expiredKey() {
        return jdbc.queryForObject("""
                INSERT INTO idempotency_keys (user_id, idempotency_key, method, path, request_hash, status, created_at)
                VALUES (1, ?, 'POST', '/x', 'h', 'COMPLETED', now() - interval '2 days') RETURNING id""",
                Long.class, UUID.randomUUID().toString());
    }

    private boolean exists(Long id) {
        return jdbc.queryForObject("SELECT count(*) FROM idempotency_keys WHERE id = ?", Integer.class, id) == 1;
    }
}
