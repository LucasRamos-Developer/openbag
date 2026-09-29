package com.openbag.modules.shared.ratelimit;

import org.junit.jupiter.api.Test;
import org.springframework.boot.autoconfigure.data.redis.RedisProperties;
import org.testcontainers.DockerClientFactory;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.utility.DockerImageName;

import java.time.Duration;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

class RateLimiterTest {

    private static RedisProperties redisAt(String host, int port) {
        RedisProperties properties = new RedisProperties();
        properties.setHost(host);
        properties.setPort(port);
        return properties;
    }

    @Test
    void limitsAreWrittenAsCapacityPerPeriod() {
        assertThat(RateLimit.parse("10/1m")).isEqualTo(new RateLimit(10, Duration.ofMinutes(1)));
        assertThat(RateLimit.parse(" 30/1h ")).isEqualTo(new RateLimit(30, Duration.ofHours(1)));
        assertThat(RateLimit.parse("5/30s")).isEqualTo(new RateLimit(5, Duration.ofSeconds(30)));
        assertThatThrownBy(() -> RateLimit.parse("10 por minuto")).hasMessageContaining("10/1m");
    }

    @Test
    void theWaitIsShownInSecondsOrMinutes() {
        assertThat(RateLimitFilter.waitText(1)).isEqualTo("1 segundo");
        assertThat(RateLimitFilter.waitText(42)).isEqualTo("42 segundos");
        assertThat(RateLimitFilter.waitText(61)).isEqualTo("2 minutos");
    }

    @Test
    void withoutRedisTheLimitStillHoldsInThisInstance() {
        // Porta sem Redis: a primeira tentativa falha rápido e os baldes ficam na memória
        RateLimiter limiter = new RateLimiter(redisAt("127.0.0.1", 1), true, "t:");
        RateLimit twoPerMinute = RateLimit.parse("2/1m");

        assertThat(limiter.tryConsume("login-ip:10.0.0.1", twoPerMinute).allowed()).isTrue();
        assertThat(limiter.tryConsume("login-ip:10.0.0.1", twoPerMinute).allowed()).isTrue();
        RateLimiter.Decision third = limiter.tryConsume("login-ip:10.0.0.1", twoPerMinute);
        assertThat(third.allowed()).isFalse();
        assertThat(third.retryAfterSeconds()).isBetween(1L, 31L);
        // Outra chave tem o próprio balde
        assertThat(limiter.tryConsume("login-ip:10.0.0.2", twoPerMinute).allowed()).isTrue();
    }

    @Test
    void withRedisTheInstancesShareTheSameCounter() {
        assumeTrue(DockerClientFactory.instance().isDockerAvailable(), "precisa do Docker");
        try (GenericContainer<?> redis = new GenericContainer<>(DockerImageName.parse("redis:7-alpine")).withExposedPorts(6379)) {
            redis.start();
            String prefix = "t-" + UUID.randomUUID() + ":";
            RateLimiter first = new RateLimiter(redisAt(redis.getHost(), redis.getMappedPort(6379)), true, prefix);
            RateLimiter second = new RateLimiter(redisAt(redis.getHost(), redis.getMappedPort(6379)), true, prefix);
            RateLimit threePerMinute = RateLimit.parse("3/1m");
            try {
                assertThat(first.tryConsume("order-user:7", threePerMinute).allowed()).isTrue();
                assertThat(first.tryConsume("order-user:7", threePerMinute).allowed()).isTrue();
                assertThat(second.tryConsume("order-user:7", threePerMinute).allowed()).isTrue();
                // As três fichas foram gastas entre as duas instâncias
                assertThat(second.tryConsume("order-user:7", threePerMinute).allowed()).isFalse();
                assertThat(first.tryConsume("order-user:7", threePerMinute).allowed()).isFalse();
            } finally {
                first.closeRedis();
                second.closeRedis();
            }
        }
    }
}
