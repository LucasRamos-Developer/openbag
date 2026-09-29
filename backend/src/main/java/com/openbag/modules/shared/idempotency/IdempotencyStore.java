package com.openbag.modules.shared.idempotency;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;

/**
 * Chaves de idempotência já vistas (tabela {@code idempotency_keys}). Cada comando roda sozinho, fora da transação
 * do pedido: a chave fica reservada antes da ação começar e é vista na hora por uma segunda requisição igual.
 */
@Component
@Slf4j
public class IdempotencyStore {

    /** Uma chave "em andamento" mais velha que isso é de uma requisição que morreu no meio e pode ser retomada */
    static final int ABANDONED_AFTER_SECONDS = 120;

    private final JdbcTemplate jdbc;
    private final int retentionHours;

    public IdempotencyStore(JdbcTemplate jdbc, @Value("${app.idempotency.retention-hours:24}") int retentionHours) {
        this.jdbc = jdbc;
        this.retentionHours = retentionHours;
    }

    public record Entry(long id, String method, String path, String requestHash, boolean completed,
                        Integer responseStatus, String responseContentType, String responseBody) {
    }

    /** Reserva a chave para esta requisição. Devolve o id da reserva, ou vazio se a chave já existia. */
    public Optional<Long> reserve(long userId, String key, String method, String path, String requestHash) {
        List<Long> ids = jdbc.queryForList("""
                INSERT INTO idempotency_keys (user_id, idempotency_key, method, path, request_hash, status)
                VALUES (?, ?, ?, ?, ?, 'IN_PROGRESS')
                ON CONFLICT (user_id, idempotency_key) DO NOTHING
                RETURNING id""", Long.class, userId, key, method, path, requestHash);
        return ids.stream().findFirst();
    }

    public Optional<Entry> find(long userId, String key) {
        return jdbc.query("""
                SELECT id, method, path, request_hash, status, response_status, response_content_type, response_body
                FROM idempotency_keys WHERE user_id = ? AND idempotency_key = ?""",
                (rs, i) -> new Entry(rs.getLong("id"), rs.getString("method"), rs.getString("path"),
                        rs.getString("request_hash"), "COMPLETED".equals(rs.getString("status")),
                        (Integer) rs.getObject("response_status"), rs.getString("response_content_type"),
                        rs.getString("response_body")),
                userId, key).stream().findFirst();
    }

    /** Retoma uma reserva abandonada (a requisição original caiu sem terminar). Devolve se conseguiu. */
    public boolean takeOverAbandoned(long id) {
        return jdbc.update("""
                UPDATE idempotency_keys SET created_at = now()
                WHERE id = ? AND status = 'IN_PROGRESS' AND created_at < now() - make_interval(secs => ?)""",
                id, ABANDONED_AFTER_SECONDS) == 1;
    }

    public void complete(long id, int status, String contentType, String body) {
        jdbc.update("""
                UPDATE idempotency_keys SET status = 'COMPLETED', response_status = ?, response_content_type = ?,
                    response_body = ?, completed_at = now()
                WHERE id = ?""", status, contentType, body, id);
    }

    /** Libera a chave (a ação falhou por um motivo passageiro e pode ser tentada de novo com ela) */
    public void release(long id) {
        jdbc.update("DELETE FROM idempotency_keys WHERE id = ?", id);
    }

    /** As chaves valem por um dia: depois disso, a mesma chave é uma ação nova */
    @Scheduled(fixedDelayString = "${app.idempotency.cleanup-ms:3600000}",
            initialDelayString = "${app.idempotency.cleanup-initial-delay-ms:300000}")
    public void deleteExpired() {
        int deleted = jdbc.update("DELETE FROM idempotency_keys WHERE created_at < now() - make_interval(hours => ?)",
                retentionHours);
        if (deleted > 0) {
            log.info("Idempotência: {} chave(s) expirada(s) apagada(s)", deleted);
        }
    }
}
