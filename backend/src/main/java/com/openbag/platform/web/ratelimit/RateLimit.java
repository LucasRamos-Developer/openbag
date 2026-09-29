package com.openbag.platform.web.ratelimit;

import io.github.bucket4j.Bandwidth;

import java.time.Duration;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Um limite: {@code capacity} requisições por {@code period}, com as fichas voltando aos poucos ao longo do período.
 * Escrito como "10/1m", "30/1h" ou "5/30s" nas propriedades {@code app.rate-limit.limits.*}.
 */
public record RateLimit(int capacity, Duration period) {

    private static final Pattern FORMAT = Pattern.compile("(\\d+)/(\\d+)([smh])");

    public static RateLimit parse(String text) {
        Matcher m = FORMAT.matcher(text.trim());
        if (!m.matches()) {
            throw new IllegalArgumentException("Limite inválido: \"" + text + "\" (use, por exemplo, 10/1m, 30/1h ou 5/30s)");
        }
        long amount = Long.parseLong(m.group(2));
        Duration period = switch (m.group(3)) {
            case "s" -> Duration.ofSeconds(amount);
            case "m" -> Duration.ofMinutes(amount);
            default -> Duration.ofHours(amount);
        };
        return new RateLimit(Integer.parseInt(m.group(1)), period);
    }

    Bandwidth bandwidth() {
        return Bandwidth.builder().capacity(capacity).refillGreedy(capacity, period).build();
    }
}
