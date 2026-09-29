package com.openbag.platform.config;

import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.core.env.Profiles;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.util.Set;
import com.openbag.platform.seed.DataInitializer;

/**
 * Impede que o backend suba em produção com segredos de desenvolvimento.
 *
 * No perfil {@code prod}, recusa a inicialização se o segredo do JWT for curto ou já tiver
 * estado no repositório, se a senha do ADMIN inicial for a de desenvolvimento ou se a conta
 * de demonstração (senha pública) estiver ligada. Nos outros perfis, só avisa no log.
 */
@Component
@Slf4j
public class SecretsValidator {

    /** Segredos do JWT que já foram publicados no repositório e nunca podem ser usados em produção */
    static final Set<String> KNOWN_JWT_SECRETS = Set.of(
            "openBagDevSecretKey2024-change-me-in-production!@#$%",
            "openBagSecretKey2024!@#$%");

    static final Set<String> KNOWN_ADMIN_PASSWORDS = Set.of("admin123");

    /** HMAC-SHA256 exige pelo menos 256 bits */
    static final int MIN_JWT_SECRET_BYTES = 32;

    static final int MIN_ADMIN_PASSWORD_LENGTH = 12;

    private final Environment environment;
    private final String jwtSecret;
    private final String adminPassword;
    private final boolean demoEnabled;

    public SecretsValidator(Environment environment,
                            @Value("${app.jwt.secret}") String jwtSecret,
                            @Value("${app.admin.password:}") String adminPassword,
                            @Value("${app.demo.enabled:false}") boolean demoEnabled) {
        this.environment = environment;
        this.jwtSecret = jwtSecret;
        this.adminPassword = adminPassword;
        this.demoEnabled = demoEnabled;
    }

    @PostConstruct
    void validate() {
        boolean production = environment.acceptsProfiles(Profiles.of("prod"));
        StringBuilder problems = new StringBuilder();

        if (jwtSecret == null || jwtSecret.getBytes(StandardCharsets.UTF_8).length < MIN_JWT_SECRET_BYTES) {
            problems.append("\n - OPENBAG_JWT_SECRET precisa ter pelo menos ")
                    .append(MIN_JWT_SECRET_BYTES).append(" bytes");
        } else if (KNOWN_JWT_SECRETS.contains(jwtSecret)) {
            problems.append("\n - OPENBAG_JWT_SECRET usa o valor de desenvolvimento, que é público");
        }

        // Senha vazia é aceita: nesse caso o ADMIN inicial não é criado (ver DataInitializer)
        if (adminPassword != null && !adminPassword.isBlank()) {
            if (KNOWN_ADMIN_PASSWORDS.contains(adminPassword)) {
                problems.append("\n - OPENBAG_ADMIN_PASSWORD usa a senha de desenvolvimento, que é pública");
            } else if (adminPassword.length() < MIN_ADMIN_PASSWORD_LENGTH) {
                problems.append("\n - OPENBAG_ADMIN_PASSWORD precisa ter pelo menos ")
                        .append(MIN_ADMIN_PASSWORD_LENGTH).append(" caracteres");
            }
        }

        if (demoEnabled) {
            problems.append("\n - OPENBAG_DEMO_ENABLED liga uma conta ADMIN com senha pública");
        }

        if (problems.isEmpty()) {
            return;
        }
        if (production) {
            throw new IllegalStateException("Configuração insegura para produção:" + problems);
        }
        log.warn("Configuração de desenvolvimento (não use em produção):{}", problems);
    }
}
