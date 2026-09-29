package com.openbag.modules.shared.ratelimit;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.Map;

/** Limites trocados por configuração, ex.: {@code app.rate-limit.limits.login-ip=20/1m} */
@Component
@ConfigurationProperties(prefix = "app.rate-limit")
@Getter
@Setter
public class RateLimitProperties {

    private Map<String, String> limits = new HashMap<>();
}
