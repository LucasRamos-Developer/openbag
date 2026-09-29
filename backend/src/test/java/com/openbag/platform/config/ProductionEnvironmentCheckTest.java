package com.openbag.platform.config;

import org.junit.jupiter.api.Test;
import org.springframework.mock.env.MockEnvironment;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class ProductionEnvironmentCheckTest {

    private final ProductionEnvironmentCheck check = new ProductionEnvironmentCheck();

    @Test
    void productionListsEveryMissingVariableAtOnce() {
        MockEnvironment environment = new MockEnvironment();
        environment.setActiveProfiles("prod");
        environment.setProperty("spring.datasource.url", "${SPRING_DATASOURCE_URL}");
        environment.setProperty("spring.datasource.username", "openbag");
        environment.setProperty("app.jwt.secret", "${OPENBAG_JWT_SECRET}");

        assertThatThrownBy(() -> check.postProcessEnvironment(environment, null))
                .hasMessageContaining("OPENBAG_CORS_ORIGINS, OPENBAG_JWT_SECRET, SPRING_DATASOURCE_PASSWORD, SPRING_DATASOURCE_URL");
    }

    @Test
    void productionWithEverythingSetStarts() {
        MockEnvironment environment = new MockEnvironment();
        environment.setActiveProfiles("prod");
        ProductionEnvironmentCheck.REQUIRED.keySet().forEach(property -> environment.setProperty(property, "x"));

        assertThatCode(() -> check.postProcessEnvironment(environment, null)).doesNotThrowAnyException();
    }

    @Test
    void developmentIsNotChecked() {
        assertThatCode(() -> check.postProcessEnvironment(new MockEnvironment(), null)).doesNotThrowAnyException();
    }
}
