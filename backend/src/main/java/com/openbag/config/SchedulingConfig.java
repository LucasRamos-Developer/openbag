package com.openbag.config;

import net.javacrumbs.shedlock.core.LockProvider;
import net.javacrumbs.shedlock.provider.jdbctemplate.JdbcTemplateLockProvider;
import net.javacrumbs.shedlock.spring.annotation.EnableSchedulerLock;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.SchedulingConfigurer;
import org.springframework.scheduling.concurrent.ThreadPoolTaskScheduler;
import org.springframework.scheduling.config.ScheduledTaskRegistrar;

import javax.sql.DataSource;

/**
 * Jobs agendados (@Scheduled). Os que não podem rodar em duas instâncias ao mesmo tempo usam @SchedulerLock
 * (ShedLock, trava na tabela {@code shedlock}); os que cuidam só da memória da instância não usam.
 */
@Configuration
@EnableScheduling
@EnableSchedulerLock(defaultLockAtMostFor = "PT10M")
public class SchedulingConfig {

    /** Agendador próprio dos jobs, de tamanho definido. Sem ele, o Spring usava o agendador do broker do WebSocket. */
    @Bean(destroyMethod = "shutdown")
    public ThreadPoolTaskScheduler jobsScheduler(@Value("${app.jobs.pool-size:4}") int poolSize) {
        ThreadPoolTaskScheduler scheduler = new ThreadPoolTaskScheduler();
        scheduler.setPoolSize(poolSize);
        scheduler.setThreadNamePrefix("jobs-");
        scheduler.initialize();
        return scheduler;
    }

    @Bean
    public SchedulingConfigurer jobsSchedulerConfigurer(ThreadPoolTaskScheduler jobsScheduler) {
        return (ScheduledTaskRegistrar registrar) -> registrar.setTaskScheduler(jobsScheduler);
    }

    /** A trava usa o relógio do banco: instâncias com relógios diferentes não se atropelam */
    @Bean
    public LockProvider lockProvider(DataSource dataSource) {
        return new JdbcTemplateLockProvider(JdbcTemplateLockProvider.Configuration.builder()
                .withJdbcTemplate(new JdbcTemplate(dataSource))
                .usingDbTime()
                .build());
    }
}
