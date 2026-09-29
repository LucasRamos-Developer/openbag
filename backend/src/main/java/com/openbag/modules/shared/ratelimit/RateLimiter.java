package com.openbag.modules.shared.ratelimit;

import io.github.bucket4j.Bucket;
import io.github.bucket4j.BucketConfiguration;
import io.github.bucket4j.ConsumptionProbe;
import io.github.bucket4j.distributed.ExpirationAfterWriteStrategy;
import io.github.bucket4j.distributed.proxy.ProxyManager;
import io.github.bucket4j.redis.lettuce.Bucket4jLettuce;
import io.lettuce.core.ClientOptions;
import io.lettuce.core.RedisClient;
import io.lettuce.core.RedisURI;
import io.lettuce.core.SocketOptions;
import io.lettuce.core.api.StatefulRedisConnection;
import io.lettuce.core.codec.ByteArrayCodec;
import io.lettuce.core.codec.RedisCodec;
import io.lettuce.core.codec.StringCodec;
import jakarta.annotation.PreDestroy;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.data.redis.RedisProperties;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Baldes de fichas (token bucket) por chave, ex.: "login-ip:203.0.113.7". Os contadores ficam no Redis, então valem
 * para todas as instâncias do backend.
 *
 * Sem Redis (desligado em desenvolvimento, ou fora do ar), os baldes ficam na memória desta instância: o limite
 * continua valendo, só não é somado entre instâncias. Depois de uma falha, o Redis só é tentado de novo depois de
 * {@link #REDIS_RETRY_AFTER}, para nenhuma requisição esperar o timeout dele.
 */
@Component
@Slf4j
public class RateLimiter {

    static final Duration REDIS_RETRY_AFTER = Duration.ofSeconds(30);
    private static final Duration REDIS_TIMEOUT = Duration.ofMillis(500);
    private static final int MAX_LOCAL_BUCKETS = 100_000;

    public record Decision(boolean allowed, long retryAfterSeconds) {
    }

    private final RedisProperties redis;
    private final boolean redisEnabled;
    private final String keyPrefix;

    private final Map<String, LocalBucket> local = new ConcurrentHashMap<>();
    private volatile ProxyManager<String> proxyManager;
    private volatile Instant redisDownUntil = Instant.MIN;
    private RedisClient client;
    private StatefulRedisConnection<String, byte[]> connection;

    public RateLimiter(RedisProperties redis,
                       @Value("${app.rate-limit.redis-enabled:true}") boolean redisEnabled,
                       @Value("${app.rate-limit.key-prefix:rl:}") String keyPrefix) {
        this.redis = redis;
        this.redisEnabled = redisEnabled;
        this.keyPrefix = keyPrefix;
    }

    /** Gasta uma ficha do balde da chave; sem ficha, diz quanto esperar */
    public Decision tryConsume(String key, RateLimit limit) {
        ProxyManager<String> manager = redisManager();
        if (manager != null) {
            try {
                return decide(manager.builder().build(keyPrefix + key, () -> configuration(limit)).tryConsumeAndReturnRemaining(1));
            } catch (RuntimeException e) {
                markRedisDown(e);
            }
        }
        LocalBucket bucket = local.computeIfAbsent(key, k -> new LocalBucket(Bucket.builder()
                .addLimit(limit.bandwidth()).build()));
        bucket.lastUsed = Instant.now();
        return decide(bucket.bucket.tryConsumeAndReturnRemaining(1));
    }

    private static Decision decide(ConsumptionProbe probe) {
        if (probe.isConsumed()) {
            return new Decision(true, 0);
        }
        return new Decision(false, Math.max(1, Duration.ofNanos(probe.getNanosToWaitForRefill()).toSeconds() + 1));
    }

    private static BucketConfiguration configuration(RateLimit limit) {
        return BucketConfiguration.builder().addLimit(limit.bandwidth()).build();
    }

    private ProxyManager<String> redisManager() {
        if (!redisEnabled || Instant.now().isBefore(redisDownUntil)) {
            return null;
        }
        if (proxyManager != null) {
            return proxyManager;
        }
        synchronized (this) {
            if (proxyManager == null && Instant.now().isAfter(redisDownUntil)) {
                try {
                    connect();
                } catch (RuntimeException e) {
                    markRedisDown(e);
                }
            }
            return proxyManager;
        }
    }

    private void connect() {
        RedisURI.Builder uri = RedisURI.builder()
                .withHost(redis.getHost())
                .withPort(redis.getPort())
                .withDatabase(redis.getDatabase())
                .withTimeout(REDIS_TIMEOUT);
        if (redis.getPassword() != null && !redis.getPassword().isBlank()) {
            uri.withPassword(redis.getPassword().toCharArray());
        }
        client = RedisClient.create(uri.build());
        client.setOptions(ClientOptions.builder()
                .socketOptions(SocketOptions.builder().connectTimeout(REDIS_TIMEOUT).build())
                // Com o Redis fora do ar, o comando falha na hora em vez de ficar na fila esperando reconectar
                .disconnectedBehavior(ClientOptions.DisconnectedBehavior.REJECT_COMMANDS)
                .build());
        connection = client.connect(RedisCodec.of(StringCodec.UTF8, ByteArrayCodec.INSTANCE));
        proxyManager = Bucket4jLettuce.casBasedBuilder(connection)
                // A chave some do Redis quando o balde enche de novo: nenhum contador fica para sempre
                .expirationAfterWrite(ExpirationAfterWriteStrategy.basedOnTimeForRefillingBucketUpToMax(Duration.ofMinutes(1)))
                .requestTimeout(REDIS_TIMEOUT)
                .build();
        log.info("Limite de requisições: contadores no Redis ({}:{})", redis.getHost(), redis.getPort());
    }

    private void markRedisDown(RuntimeException e) {
        if (Instant.now().isAfter(redisDownUntil)) {
            log.warn("Limite de requisições: Redis indisponível ({}); usando contadores desta instância por {} s",
                    e.getMessage(), REDIS_RETRY_AFTER.toSeconds());
        }
        redisDownUntil = Instant.now().plus(REDIS_RETRY_AFTER);
        closeRedis();
    }

    /** Baldes locais sem uso há uma hora já estão cheios de novo: podem sair da memória */
    @Scheduled(fixedDelay = 600_000)
    void evictIdleLocalBuckets() {
        Instant idleSince = Instant.now().minus(Duration.ofHours(1));
        local.values().removeIf(bucket -> bucket.lastUsed.isBefore(idleSince));
        if (local.size() > MAX_LOCAL_BUCKETS) {
            // Proteção contra memória: numa enxurrada de IPs diferentes, recomeça a contagem
            log.warn("Limite de requisições: {} baldes na memória; limpando", local.size());
            local.clear();
        }
    }

    @PreDestroy
    synchronized void closeRedis() {
        proxyManager = null;
        if (connection != null) {
            connection.closeAsync();
            connection = null;
        }
        if (client != null) {
            client.shutdownAsync();
            client = null;
        }
    }

    private static final class LocalBucket {
        final Bucket bucket;
        volatile Instant lastUsed = Instant.now();

        LocalBucket(Bucket bucket) {
            this.bucket = bucket;
        }
    }
}
