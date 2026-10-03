package com.smarthas.backend.plsql;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Fase 6: liga a camada Oracle PL/SQL ao backend da Fase 5.
 *
 * O pool Oracle e criado aqui dentro e NAO e exposto como bean DataSource:
 * assim a autoconfiguracao do Spring Boot continua criando o DataSource H2
 * usado pelo JPA, e os dois bancos convivem sem conflito.
 * Ativado com smarthas.oracle.enabled=true (variavel ORACLE_ENABLED).
 */
@Configuration
@ConditionalOnProperty(name = "smarthas.oracle.enabled", havingValue = "true")
public class PlsqlConfig {

    /**
     * O pool e criado aqui e entregue ao repositorio, sem virar bean do tipo
     * DataSource (um bean DataSource desligaria a autoconfiguracao do H2).
     */
    @Bean(destroyMethod = "close")
    public OraclePlsqlRepository oraclePlsqlRepository(@Value("${smarthas.oracle.url}") String url,
                                                       @Value("${smarthas.oracle.username}") String username,
                                                       @Value("${smarthas.oracle.password}") String password) {
        HikariConfig config = new HikariConfig();
        config.setPoolName("oracle-plsql");
        config.setJdbcUrl(url);
        config.setUsername(username);
        config.setPassword(password);
        config.setDriverClassName("oracle.jdbc.OracleDriver");
        config.setMaximumPoolSize(5);
        config.setConnectionTimeout(10_000);
        // Sobe a API mesmo que o Oracle ainda nao esteja no ar.
        config.setInitializationFailTimeout(-1);
        return new OraclePlsqlRepository(new HikariDataSource(config));
    }

    @Bean
    public OraclePlsqlService oraclePlsqlService(OraclePlsqlRepository repository) {
        return new OraclePlsqlService(repository);
    }
}
