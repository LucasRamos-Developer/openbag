package com.openbag.config;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.env.EnvironmentPostProcessor;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.Profiles;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * No perfil {@code prod}, confere antes de tudo que as variáveis obrigatórias existem e lista todas as que faltam de
 * uma vez. Sem isso, o primeiro erro seria do banco, com um "${SPRING_DATASOURCE_URL}" literal no lugar da URL.
 * A qualidade dos segredos (tamanho, valores de desenvolvimento) é conferida depois, pelo {@link SecretsValidator}.
 */
public class ProductionEnvironmentCheck implements EnvironmentPostProcessor {

    /** Propriedade → variável de ambiente que a preenche (ver application-prod.properties) */
    static final Map<String, String> REQUIRED = Map.of(
            "spring.datasource.url", "SPRING_DATASOURCE_URL",
            "spring.datasource.username", "SPRING_DATASOURCE_USERNAME",
            "spring.datasource.password", "SPRING_DATASOURCE_PASSWORD",
            "app.jwt.secret", "OPENBAG_JWT_SECRET",
            "app.cors.allowed-origins", "OPENBAG_CORS_ORIGINS");

    @Override
    public void postProcessEnvironment(ConfigurableEnvironment environment, SpringApplication application) {
        if (!environment.acceptsProfiles(Profiles.of("prod"))) {
            return;
        }
        List<String> missing = new ArrayList<>();
        REQUIRED.forEach((property, variable) -> {
            String value;
            try {
                value = environment.getProperty(property);
            } catch (IllegalArgumentException unresolved) {
                value = null;
            }
            if (value == null || value.isBlank()) {
                missing.add(variable);
            }
        });
        if (!missing.isEmpty()) {
            missing.sort(null);
            throw new IllegalStateException("Perfil prod sem as variáveis de ambiente obrigatórias: "
                    + String.join(", ", missing) + " (veja \"Produção (perfil prod)\" no README-DEVELOPER)");
        }
    }
}
