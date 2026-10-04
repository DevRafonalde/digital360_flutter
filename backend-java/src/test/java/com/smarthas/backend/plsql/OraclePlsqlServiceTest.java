package com.smarthas.backend.plsql;

import com.smarthas.backend.exception.ApiException;
import com.smarthas.backend.plsql.dto.OracleLeituraRequest;
import com.smarthas.backend.plsql.dto.OracleRiscoLogistico;
import org.springframework.http.HttpStatus;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.anyDouble;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class OraclePlsqlServiceTest {

    private OraclePlsqlRepository repository;
    private OraclePlsqlService service;

    @BeforeEach
    void setUp() {
        repository = mock(OraclePlsqlRepository.class);
        service = new OraclePlsqlService(repository);
    }

    @Test
    void recalcularRiscoDelegaParaProcedure() {
        OracleRiscoLogistico esperado = new OracleRiscoLogistico(2, 100, "CRITICO", "Acionar suporte", "Detectamos fatores");
        when(repository.recalcularRisco(2)).thenReturn(esperado);

        assertEquals(esperado, service.recalcularRisco(2));
    }

    @Test
    void recalcularRiscoRejeitaIdInvalidoSemIrAoBanco() {
        ApiException e = assertThrows(ApiException.class, () -> service.recalcularRisco(0));
        assertEquals(HttpStatus.BAD_REQUEST, e.getStatus());
        verify(repository, never()).recalcularRisco(anyLong());
    }

    @Test
    void registrarLeituraExigeValor() {
        assertThrows(ApiException.class, () -> service.registrarLeitura(1, new OracleLeituraRequest(null)));
        assertThrows(ApiException.class, () -> service.registrarLeitura(1, new OracleLeituraRequest(Double.NaN)));
        verify(repository, never()).registrarLeitura(anyLong(), anyDouble());
    }

    @Test
    void buscarPedidoInexistenteGeraNaoEncontrado() {
        when(repository.buscarPedido(99)).thenReturn(Optional.empty());
        assertThrows(ApiException.class, () -> service.buscarPedido(99));
    }

    @Test
    void listarAlertasNormalizaEValidaStatus() {
        service.listarAlertas(" aberto ");
        verify(repository).listarAlertas("ABERTO");

        service.listarAlertas(null);
        verify(repository).listarAlertas(null);

        assertThrows(ApiException.class, () -> service.listarAlertas("PENDENTE"));
    }
}
