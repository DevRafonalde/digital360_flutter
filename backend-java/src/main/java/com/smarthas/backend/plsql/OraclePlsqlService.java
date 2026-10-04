package com.smarthas.backend.plsql;

import com.smarthas.backend.exception.ApiException;
import com.smarthas.backend.plsql.dto.OracleAlerta;
import com.smarthas.backend.plsql.dto.OracleLeituraRegistrada;
import com.smarthas.backend.plsql.dto.OracleLeituraRequest;
import com.smarthas.backend.plsql.dto.OraclePedido;
import com.smarthas.backend.plsql.dto.OracleRelatorioUsuario;
import com.smarthas.backend.plsql.dto.OracleRiscoLogistico;
import org.springframework.http.HttpStatus;

import java.util.List;
import java.util.Locale;
import java.util.Set;

/**
 * Fase 6: validacao de entrada e orquestracao da camada Oracle PL/SQL.
 * As regras de risco, alertas e relatorio vivem no banco (functions e
 * procedures); este servico so valida e delega para o repositorio JDBC.
 */
public class OraclePlsqlService {

    private static final Set<String> STATUS_ALERTA = Set.of("ABERTO", "RESOLVIDO");

    private final OraclePlsqlRepository repository;

    public OraclePlsqlService(OraclePlsqlRepository repository) {
        this.repository = repository;
    }

    public List<OraclePedido> listarPedidos() {
        return repository.listarPedidos();
    }

    public OraclePedido buscarPedido(long idPedido) {
        validarId(idPedido, "pedido");
        return repository.buscarPedido(idPedido)
                .orElseThrow(() -> ApiException.notFound("Pedido nao encontrado no Oracle (ID " + idPedido + ")."));
    }

    public OracleRiscoLogistico recalcularRisco(long idPedido) {
        validarId(idPedido, "pedido");
        return repository.recalcularRisco(idPedido);
    }

    public OracleLeituraRegistrada registrarLeitura(long idSensor, OracleLeituraRequest request) {
        validarId(idSensor, "sensor");
        if (request == null || request.valor() == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Informe o campo 'valor' da leitura.");
        }
        if (request.valor().isNaN() || request.valor().isInfinite()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Valor de leitura invalido.");
        }
        return repository.registrarLeitura(idSensor, request.valor());
    }

    public List<OracleAlerta> listarAlertas(String status) {
        String filtro = (status == null || status.isBlank()) ? null : status.trim().toUpperCase(Locale.ROOT);
        if (filtro != null && !STATUS_ALERTA.contains(filtro)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Status invalido. Use ABERTO ou RESOLVIDO.");
        }
        return repository.listarAlertas(filtro);
    }

    public List<OracleRelatorioUsuario> gerarRelatorioUsuarios() {
        return repository.gerarRelatorioUsuarios();
    }

    private static void validarId(long id, String recurso) {
        if (id <= 0) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "ID de " + recurso + " deve ser maior que zero.");
        }
    }
}
