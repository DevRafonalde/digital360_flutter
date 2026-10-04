package com.smarthas.backend.plsql;

import com.smarthas.backend.exception.ApiException;
import com.smarthas.backend.plsql.dto.OracleAlerta;
import com.smarthas.backend.plsql.dto.OracleLeituraRegistrada;
import com.smarthas.backend.plsql.dto.OraclePedido;
import com.smarthas.backend.plsql.dto.OracleRelatorioUsuario;
import com.smarthas.backend.plsql.dto.OracleRiscoLogistico;

import javax.sql.DataSource;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Camada de acesso ao Oracle via JDBC puro (java.sql).
 *
 * Toda regra de negocio de risco e alertas fica no banco (PL/SQL);
 * esta classe apenas chama as functions/procedures e mapeia o resultado.
 * Fluxo de integracao: REST (Controller) -> Service -> este Repository
 * -> JDBC (CallableStatement) -> Oracle (procedure).
 *
 * Classe sem dependencia de framework: e registrada como bean em
 * {@code PlsqlConfig} e pode ser testada com um DataSource simulado.
 */
public class OraclePlsqlRepository implements AutoCloseable {

    static final String SQL_LISTAR_PEDIDOS =
            "SELECT ID_PEDIDO, CD_PEDIDO, DS_PRODUTO, DS_TIPO_PRODUTO, DS_REGIAO_ENTREGA, NR_DISTANCIA_KM, "
          + "       DT_PRAZO, ST_PEDIDO, NM_PARCEIRO, FL_ESTOQUE, NR_HIST_ATRASOS, NR_REAGENDAMENTOS, "
          + "       VL_LATITUDE, VL_LONGITUDE, NR_SCORE_RISCO, DS_NIVEL_RISCO, DS_RESUMO "
          + "  FROM V_SH_PEDIDO_RISCO";

    static final String CALL_RECALCULAR_RISCO = "{call SP_RECALCULAR_RISCO(?, ?, ?, ?, ?)}";
    static final String CALL_REGISTRAR_ALERTAS = "{call SP_REGISTRAR_ALERTAS_SENSORES(?, ?)}";
    static final String CALL_GERAR_RELATORIO = "{call SP_GERAR_RELATORIO_USUARIOS(?, ?)}";

    static final String SQL_PEDIDO_DO_SENSOR = "SELECT ID_PEDIDO FROM T_SH_SENSOR WHERE ID_SENSOR = ?";
    static final String SQL_PROXIMA_LEITURA = "SELECT SEQ_SH_LEITURA.NEXTVAL FROM DUAL";
    static final String SQL_INSERIR_LEITURA =
            "INSERT INTO T_SH_LEITURA (ID_LEITURA, ID_SENSOR, DT_LEITURA, VL_LEITURA, FL_PROCESSADA) "
          + "VALUES (?, ?, SYSTIMESTAMP, ?, 'N')";

    static final String SQL_LISTAR_ALERTAS =
            "SELECT a.ID_ALERTA, a.ID_PEDIDO, p.CD_PEDIDO, a.DS_ORIGEM, a.DS_NIVEL, a.DS_MENSAGEM, "
          + "       a.DT_ALERTA, a.ST_ALERTA "
          + "  FROM T_SH_ALERTA a JOIN T_SH_PEDIDO p ON p.ID_PEDIDO = a.ID_PEDIDO "
          + " WHERE (? IS NULL OR a.ST_ALERTA = ?) "
          + " ORDER BY a.DT_ALERTA DESC, a.ID_ALERTA DESC";

    static final String SQL_ULTIMO_RELATORIO =
            "SELECT r.ID_USUARIO, u.NM_USUARIO, r.QT_CURSOS, r.VL_PROGRESSO_MEDIO, r.QT_PEDIDOS, "
          + "       r.QT_ALERTAS_ABERTOS, r.DS_CLASSIFICACAO, r.DT_GERACAO "
          + "  FROM T_SH_RELATORIO_USUARIO r JOIN T_SH_USUARIO u ON u.ID_USUARIO = r.ID_USUARIO "
          + " WHERE r.ID_RELATORIO IN (SELECT MAX(ID_RELATORIO) FROM T_SH_RELATORIO_USUARIO GROUP BY ID_USUARIO) "
          + " ORDER BY r.ID_USUARIO";

    private final DataSource dataSource;

    public OraclePlsqlRepository(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    /** Fecha o pool Oracle quando o contexto do Spring encerra. */
    @Override
    public void close() throws Exception {
        if (dataSource instanceof AutoCloseable closeable) {
            closeable.close();
        }
    }

    // ------------------------------------------------------------------ pedidos

    /** Lista os pedidos com risco calculado pelas functions (view V_SH_PEDIDO_RISCO). */
    public List<OraclePedido> listarPedidos() {
        String sql = SQL_LISTAR_PEDIDOS + " ORDER BY ID_PEDIDO";
        try (Connection con = dataSource.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            List<OraclePedido> pedidos = new ArrayList<>();
            while (rs.next()) {
                pedidos.add(mapearPedido(rs));
            }
            return pedidos;
        } catch (SQLException e) {
            throw OracleErrorTranslator.traduzir("listar pedidos", e);
        }
    }

    public Optional<OraclePedido> buscarPedido(long idPedido) {
        String sql = SQL_LISTAR_PEDIDOS + " WHERE ID_PEDIDO = ?";
        try (Connection con = dataSource.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setLong(1, idPedido);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? Optional.of(mapearPedido(rs)) : Optional.empty();
            }
        } catch (SQLException e) {
            throw OracleErrorTranslator.traduzir("buscar pedido", e);
        }
    }

    // ------------------------------------------------------- motor de risco

    /**
     * Aciona a procedure SP_RECALCULAR_RISCO (parametro IN + 4 OUT).
     * E a procedure disparada por evento de back-end (POST do app).
     */
    public OracleRiscoLogistico recalcularRisco(long idPedido) {
        try (Connection con = dataSource.getConnection();
             CallableStatement cs = con.prepareCall(CALL_RECALCULAR_RISCO)) {
            cs.setLong(1, idPedido);
            cs.registerOutParameter(2, Types.NUMERIC);
            cs.registerOutParameter(3, Types.VARCHAR);
            cs.registerOutParameter(4, Types.VARCHAR);
            cs.registerOutParameter(5, Types.VARCHAR);
            cs.execute();
            return new OracleRiscoLogistico(idPedido, cs.getInt(2), cs.getString(3), cs.getString(4), cs.getString(5));
        } catch (SQLException e) {
            throw OracleErrorTranslator.traduzir("recalcular risco", e);
        }
    }

    // ------------------------------------------------------------- IoT

    /**
     * Grava uma leitura de sensor e, na MESMA transacao, aciona
     * SP_REGISTRAR_ALERTAS_SENSORES para o pedido do sensor.
     */
    public OracleLeituraRegistrada registrarLeitura(long idSensor, double valor) {
        try (Connection con = dataSource.getConnection()) {
            boolean autoCommitOriginal = con.getAutoCommit();
            con.setAutoCommit(false);
            try {
                long idPedido = buscarPedidoDoSensor(con, idSensor);
                long idLeitura = proximoIdLeitura(con);

                try (PreparedStatement ps = con.prepareStatement(SQL_INSERIR_LEITURA)) {
                    ps.setLong(1, idLeitura);
                    ps.setLong(2, idSensor);
                    ps.setDouble(3, valor);
                    ps.executeUpdate();
                }

                int alertas;
                try (CallableStatement cs = con.prepareCall(CALL_REGISTRAR_ALERTAS)) {
                    cs.setLong(1, idPedido);
                    cs.registerOutParameter(2, Types.NUMERIC);
                    cs.execute();
                    alertas = cs.getInt(2);
                }

                con.commit();
                return new OracleLeituraRegistrada(idLeitura, idSensor, idPedido, valor, alertas);
            } catch (SQLException | RuntimeException e) {
                con.rollback();
                throw e;
            } finally {
                con.setAutoCommit(autoCommitOriginal);
            }
        } catch (SQLException e) {
            throw OracleErrorTranslator.traduzir("registrar leitura", e);
        }
    }

    private long buscarPedidoDoSensor(Connection con, long idSensor) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(SQL_PEDIDO_DO_SENSOR)) {
            ps.setLong(1, idSensor);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw ApiException.notFound("Sensor nao encontrado (ID " + idSensor + ").");
                }
                return rs.getLong(1);
            }
        }
    }

    private long proximoIdLeitura(Connection con) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(SQL_PROXIMA_LEITURA);
             ResultSet rs = ps.executeQuery()) {
            rs.next();
            return rs.getLong(1);
        }
    }

    // ----------------------------------------------------------- alertas

    /** Lista alertas; status nulo traz todos. */
    public List<OracleAlerta> listarAlertas(String status) {
        try (Connection con = dataSource.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_LISTAR_ALERTAS)) {
            ps.setString(1, status);
            ps.setString(2, status);
            try (ResultSet rs = ps.executeQuery()) {
                List<OracleAlerta> alertas = new ArrayList<>();
                while (rs.next()) {
                    alertas.add(new OracleAlerta(
                            rs.getLong("ID_ALERTA"),
                            rs.getLong("ID_PEDIDO"),
                            rs.getString("CD_PEDIDO"),
                            rs.getString("DS_ORIGEM"),
                            rs.getString("DS_NIVEL"),
                            rs.getString("DS_MENSAGEM"),
                            formatarDataHora(rs.getTimestamp("DT_ALERTA")),
                            rs.getString("ST_ALERTA")));
                }
                return alertas;
            }
        } catch (SQLException e) {
            throw OracleErrorTranslator.traduzir("listar alertas", e);
        }
    }

    // --------------------------------------------------------- relatorio

    /** Executa SP_GERAR_RELATORIO_USUARIOS e devolve o snapshot mais recente por usuario. */
    public List<OracleRelatorioUsuario> gerarRelatorioUsuarios() {
        try (Connection con = dataSource.getConnection()) {
            try (CallableStatement cs = con.prepareCall(CALL_GERAR_RELATORIO)) {
                cs.setNull(1, Types.NUMERIC);
                cs.registerOutParameter(2, Types.NUMERIC);
                cs.execute();
            }
            try (PreparedStatement ps = con.prepareStatement(SQL_ULTIMO_RELATORIO);
                 ResultSet rs = ps.executeQuery()) {
                List<OracleRelatorioUsuario> linhas = new ArrayList<>();
                while (rs.next()) {
                    linhas.add(new OracleRelatorioUsuario(
                            rs.getLong("ID_USUARIO"),
                            rs.getString("NM_USUARIO"),
                            rs.getInt("QT_CURSOS"),
                            rs.getDouble("VL_PROGRESSO_MEDIO"),
                            rs.getInt("QT_PEDIDOS"),
                            rs.getInt("QT_ALERTAS_ABERTOS"),
                            rs.getString("DS_CLASSIFICACAO"),
                            formatarDataHora(rs.getTimestamp("DT_GERACAO"))));
                }
                return linhas;
            }
        } catch (SQLException e) {
            throw OracleErrorTranslator.traduzir("gerar relatorio de usuarios", e);
        }
    }

    // ----------------------------------------------------------- mapeamento

    private OraclePedido mapearPedido(ResultSet rs) throws SQLException {
        return new OraclePedido(
                rs.getLong("ID_PEDIDO"),
                rs.getString("CD_PEDIDO"),
                rs.getString("DS_PRODUTO"),
                rs.getString("DS_TIPO_PRODUTO"),
                rs.getString("DS_REGIAO_ENTREGA"),
                rs.getInt("NR_DISTANCIA_KM"),
                formatarData(rs.getTimestamp("DT_PRAZO")),
                rs.getString("ST_PEDIDO"),
                rs.getString("NM_PARCEIRO"),
                "S".equals(rs.getString("FL_ESTOQUE")),
                rs.getInt("NR_HIST_ATRASOS"),
                rs.getInt("NR_REAGENDAMENTOS"),
                rs.getDouble("VL_LATITUDE"),
                rs.getDouble("VL_LONGITUDE"),
                rs.getInt("NR_SCORE_RISCO"),
                rs.getString("DS_NIVEL_RISCO"),
                rs.getString("DS_RESUMO"));
    }

    static String formatarData(Timestamp ts) {
        return ts == null ? null : new SimpleDateFormat("dd/MM/yyyy").format(ts);
    }

    static String formatarDataHora(Timestamp ts) {
        return ts == null ? null : new SimpleDateFormat("dd/MM/yyyy HH:mm:ss").format(ts);
    }
}
