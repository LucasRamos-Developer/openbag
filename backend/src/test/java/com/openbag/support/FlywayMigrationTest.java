package com.openbag.support;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * O contexto só sobe se as migrações criarem exatamente o esquema que as entidades esperam
 * (ddl-auto=validate). Entidade nova ou alterada sem migração quebra este teste.
 */
class FlywayMigrationTest extends IntegrationTest {

    @Autowired
    private JdbcTemplate jdbc;

    @Test
    void migrationsCreateTheSchemaTheEntitiesExpect() {
        List<String> versions = jdbc.queryForList(
                "SELECT version FROM flyway_schema_history WHERE success ORDER BY installed_rank", String.class);

        assertThat(versions).startsWith("1", "2");
        assertThat(jdbc.queryForObject("SELECT count(*) FROM pg_extension WHERE extname = 'postgis'", Integer.class))
                .isEqualTo(1);
        assertThat(jdbc.queryForObject(
                "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'orders'",
                Integer.class)).isEqualTo(1);
    }

    @Test
    void startupDataIsCreatedOnTopOfTheMigrations() {
        // DataInitializer: roles, permissões e o ADMIN inicial
        assertThat(jdbc.queryForObject("SELECT count(*) FROM roles", Integer.class)).isPositive();
        assertThat(jdbc.queryForObject(
                "SELECT count(*) FROM users u JOIN user_roles ur ON ur.user_id = u.id JOIN roles r ON r.id = ur.role_id "
                        + "WHERE r.name = 'ADMIN'", Integer.class)).isEqualTo(1);
    }
}
