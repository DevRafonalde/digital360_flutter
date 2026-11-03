package com.smarthas.backend.plsql;

import com.smarthas.backend.exception.ApiException;
import com.smarthas.backend.plsql.dto.OracleLeituraRegistrada;
import com.smarthas.backend.plsql.dto.OracleResumoPedidos;
import com.smarthas.backend.plsql.dto.OracleRiscoLogistico;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import javax.sql.DataSource;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/** Testa a integracao JDBC (chamada das procedures) sem precisar de um Oracle no ar. */
class OraclePlsqlRepositoryTest {

    private Connection con;
    private OraclePlsqlRepository repository;

    @BeforeEach
    void setUp() throws SQLException {
        DataSource ds = mock(DataSource.class);
        con = mock(Connection.class);
        when(ds.getConnection()).thenReturn(con);
        when(con.getAutoCommit()).thenReturn(true);
        repository = new OraclePlsqlRepository(ds);
    }

    @Test
    void recalcularRiscoChamaProcedureComParametrosInEOut() throws SQLException {
        CallableStatement cs = mock(CallableStatement.class);
        when(con.prepareCall("{call PKG_SH_RISCO.SP_RECALCULAR_RISCO(?, ?, ?, ?, ?)}")).thenReturn(cs);
        when(cs.getInt(2)).thenReturn(100);
        when(cs.getString(3)).thenReturn("CRITICO");
        when(cs.getString(4)).thenReturn("Acionar suporte logistico e oferecer reagendamento proativo.");
        when(cs.getString(5)).thenReturn("Detectamos fatores que podem afetar a janela prometida.");

        OracleRiscoLogistico r = repository.recalcularRisco(2);

        verify(cs).setLong(1, 2);
        verify(cs).registerOutParameter(2, Types.NUMERIC);
        verify(cs).registerOutParameter(3, Types.VARCHAR);
        verify(cs).execute();
        assertEquals(100, r.riscoScore());
        assertEquals("CRITICO", r.riscoNivel());
    }

    @Test
    void buscarPedidosEnviaFiltroNuloComoNullELeOCursorRetornado() throws SQLException {
        CallableStatement cs = mock(CallableStatement.class);
        ResultSet rs = mock(ResultSet.class);
        when(con.prepareCall(OraclePlsqlRepository.CALL_BUSCAR_PEDIDOS)).thenReturn(cs);
        when(cs.getObject(1, ResultSet.class)).thenReturn(rs);
        when(rs.next()).thenReturn(false);

        assertEquals(0, repository.buscarPedidos("ATRASADO", null, null, null, "score", "DESC").size());

        verify(cs).registerOutParameter(1, Types.REF_CURSOR);
        verify(cs).setString(2, "ATRASADO");
        verify(cs).setString(3, null);
        verify(cs).setNull(5, Types.NUMERIC);
        verify(cs).execute();
        verify(rs).close();
    }

    @Test
    void resumirPedidosMapeiaAsColunasDoCursor() throws SQLException {
        CallableStatement cs = mock(CallableStatement.class);
        ResultSet rs = mock(ResultSet.class);
        when(con.prepareCall(OraclePlsqlRepository.CALL_RESUMO_PEDIDOS)).thenReturn(cs);
        when(cs.getObject(1, ResultSet.class)).thenReturn(rs);
        when(rs.next()).thenReturn(true, false);
        when(rs.getString("DS_GRUPO")).thenReturn("Correios");
        when(rs.getInt("QT_PEDIDOS")).thenReturn(2);
        when(rs.getDouble("VL_SCORE_MEDIO")).thenReturn(35.5);
        when(rs.getInt("QT_EM_RISCO")).thenReturn(0);

        OracleResumoPedidos linha = repository.resumirPedidos("parceiro").get(0);

        verify(cs).setString(2, "parceiro");
        assertEquals(new OracleResumoPedidos("Correios", 2, 35.5, 0), linha);
    }

    @Test
    void resolverAlertaChamaAProcedureDoPacote() throws SQLException {
        CallableStatement cs = mock(CallableStatement.class);
        when(con.prepareCall("{call PKG_SH_IOT.SP_RESOLVER_ALERTA(?)}")).thenReturn(cs);

        repository.resolverAlerta(7);

        verify(cs).setLong(1, 7);
        verify(cs).execute();
    }

    @Test
    void registrarLeituraGravaEDisparaAlertasNaMesmaTransacao() throws SQLException {
        PreparedStatement psSensor = mock(PreparedStatement.class);
        ResultSet rsSensor = mock(ResultSet.class);
        when(con.prepareStatement(OraclePlsqlRepository.SQL_PEDIDO_DO_SENSOR)).thenReturn(psSensor);
        when(psSensor.executeQuery()).thenReturn(rsSensor);
        when(rsSensor.next()).thenReturn(true);
        when(rsSensor.getLong(1)).thenReturn(2L);

        PreparedStatement psSeq = mock(PreparedStatement.class);
        ResultSet rsSeq = mock(ResultSet.class);
        when(con.prepareStatement(OraclePlsqlRepository.SQL_PROXIMA_LEITURA)).thenReturn(psSeq);
        when(psSeq.executeQuery()).thenReturn(rsSeq);
        when(rsSeq.next()).thenReturn(true);
        when(rsSeq.getLong(1)).thenReturn(1000L);

        PreparedStatement psInsert = mock(PreparedStatement.class);
        when(con.prepareStatement(OraclePlsqlRepository.SQL_INSERIR_LEITURA)).thenReturn(psInsert);

        CallableStatement cs = mock(CallableStatement.class);
        when(con.prepareCall(OraclePlsqlRepository.CALL_REGISTRAR_ALERTAS)).thenReturn(cs);
        when(cs.getInt(2)).thenReturn(1);

        OracleLeituraRegistrada r = repository.registrarLeitura(1, 55.0);

        assertEquals(1000L, r.leituraId());
        assertEquals(2L, r.pedidoId());
        assertEquals(1, r.alertasGerados());
        verify(con).setAutoCommit(false);
        verify(psInsert).executeUpdate();
        verify(cs).setLong(1, 2L);
        verify(con).commit();
        verify(con, never()).rollback();
    }

    @Test
    void sensorInexistenteFazRollbackENaoGravaLeitura() throws SQLException {
        PreparedStatement psSensor = mock(PreparedStatement.class);
        ResultSet rsSensor = mock(ResultSet.class);
        when(con.prepareStatement(OraclePlsqlRepository.SQL_PEDIDO_DO_SENSOR)).thenReturn(psSensor);
        when(psSensor.executeQuery()).thenReturn(rsSensor);
        when(rsSensor.next()).thenReturn(false);

        assertThrows(ApiException.class, () -> repository.registrarLeitura(99, 10.0));
        verify(con).rollback();
        verify(con, never()).commit();
    }
}
