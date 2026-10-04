package com.smarthas.backend.plsql;

import com.smarthas.backend.exception.ApiException;
import org.springframework.http.HttpStatus;

import org.junit.jupiter.api.Test;

import java.sql.SQLException;

import static org.junit.jupiter.api.Assertions.assertEquals;

class OracleErrorTranslatorTest {

    @Test
    void ora20001ViraNaoEncontradoComMensagemLimpa() {
        SQLException e = new SQLException(
                "ORA-20001: FN_CALCULA_RISCO: pedido nao encontrado (ID 999).\nORA-06512: at \"SMARTHAS.FN_CALCULA_RISCO\", line 40",
                "72000", 20001);

        ApiException r = OracleErrorTranslator.traduzir("recalcular risco", e);

        assertEquals(HttpStatus.NOT_FOUND, r.getStatus());
        assertEquals("FN_CALCULA_RISCO: pedido nao encontrado (ID 999).", r.getMessage());
    }

    @Test
    void ora20002ViraRegraNegocio() {
        SQLException e = new SQLException("ORA-20002: parametro nulo", "72000", 20002);
        assertEquals(HttpStatus.BAD_REQUEST, OracleErrorTranslator.traduzir("x", e).getStatus());
    }

    @Test
    void outrosErrosViramFalhaDeBanco() {
        SQLException e = new SQLException("ORA-12541: TNS:no listener", "08006", 12541);
        assertEquals(HttpStatus.SERVICE_UNAVAILABLE, OracleErrorTranslator.traduzir("x", e).getStatus());
    }
}
