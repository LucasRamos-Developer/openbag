package com.openbag.config;

import org.junit.jupiter.api.Test;
import org.springframework.mock.env.MockEnvironment;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class SecretsValidatorTest {

    private static final String STRONG_SECRET = "c2VjcmV0by1mb3J0ZS1jb20tbWFpcy1kZS0zMi1ieXRlcw==";
    private static final String DEV_SECRET = "openBagDevSecretKey2024-change-me-in-production!@#$%";

    private static MockEnvironment profile(String... profiles) {
        MockEnvironment environment = new MockEnvironment();
        environment.setActiveProfiles(profiles);
        return environment;
    }

    @Test
    void productionRefusesTheDevelopmentJwtSecret() {
        SecretsValidator validator = new SecretsValidator(profile("prod"), DEV_SECRET, "", false);

        assertThatThrownBy(validator::validate)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("OPENBAG_JWT_SECRET");
    }

    @Test
    void productionRefusesShortSecretsDefaultAdminPasswordAndTheDemoAccount() {
        assertThatThrownBy(new SecretsValidator(profile("prod"), "curto", "", false)::validate)
                .hasMessageContaining("32 bytes");
        assertThatThrownBy(new SecretsValidator(profile("prod"), STRONG_SECRET, "admin123", false)::validate)
                .hasMessageContaining("OPENBAG_ADMIN_PASSWORD");
        assertThatThrownBy(new SecretsValidator(profile("prod"), STRONG_SECRET, "curta", false)::validate)
                .hasMessageContaining("12 caracteres");
        assertThatThrownBy(new SecretsValidator(profile("prod"), STRONG_SECRET, "", true)::validate)
                .hasMessageContaining("OPENBAG_DEMO_ENABLED");
    }

    @Test
    void productionStartsWithStrongSecretsOrWithoutInitialAdmin() {
        assertThatCode(new SecretsValidator(profile("prod"), STRONG_SECRET, "", false)::validate)
                .doesNotThrowAnyException();
        assertThatCode(new SecretsValidator(profile("prod"), STRONG_SECRET, "uma-senha-bem-longa", false)::validate)
                .doesNotThrowAnyException();
    }

    @Test
    void developmentOnlyWarns() {
        assertThatCode(new SecretsValidator(profile(), DEV_SECRET, "admin123", true)::validate)
                .doesNotThrowAnyException();
        assertThatCode(new SecretsValidator(profile("docker"), DEV_SECRET, "admin123", true)::validate)
                .doesNotThrowAnyException();
    }
}
