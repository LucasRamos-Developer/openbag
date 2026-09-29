package com.openbag.support;

import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.images.builder.ImageFromDockerfile;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

import java.nio.file.Path;

/**
 * Base dos testes de integração: sobe o backend inteiro contra um Postgres + PostGIS de verdade,
 * com o esquema criado só pelas migrações do Flyway (e conferido pelo Hibernate com ddl-auto=validate).
 *
 * O banco é a mesma imagem do docker-compose ({@code database/Dockerfile}), construída uma vez e
 * reaproveitada por todas as classes. Sem Docker, os testes são pulados.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Testcontainers(disabledWithoutDocker = true)
public abstract class IntegrationTest {

    static final PostgreSQLContainer<?> POSTGRES;

    static {
        String image = new ImageFromDockerfile("openbag-postgres-test", false)
                .withFileFromPath(".", Path.of("..", "database"))
                .get();
        POSTGRES = new PostgreSQLContainer<>(DockerImageName.parse(image).asCompatibleSubstituteFor("postgres"))
                .withDatabaseName("openbag")
                .withUsername("openbag")
                .withPassword("openbag");
        if (org.testcontainers.DockerClientFactory.instance().isDockerAvailable()) {
            POSTGRES.start();
        }
    }

    @DynamicPropertySource
    static void database(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
    }
}
