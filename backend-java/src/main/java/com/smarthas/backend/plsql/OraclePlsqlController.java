package com.smarthas.backend.plsql;

import com.smarthas.backend.plsql.dto.OracleAlerta;
import com.smarthas.backend.plsql.dto.OracleAuditoriaAlerta;
import com.smarthas.backend.plsql.dto.OracleLeituraRegistrada;
import com.smarthas.backend.plsql.dto.OracleLeituraRequest;
import com.smarthas.backend.plsql.dto.OraclePedido;
import com.smarthas.backend.plsql.dto.OracleRelatorioUsuario;
import com.smarthas.backend.plsql.dto.OracleResumoPedidos;
import com.smarthas.backend.plsql.dto.OracleRiscoLogistico;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Fase 6: endpoints que acionam a camada Oracle PL/SQL
 * (REST -> Java -> JDBC -> Oracle). So existem quando
 * {@code smarthas.oracle.enabled=true}; com o padrao (false) o backend
 * continua exatamente como na Fase 5, apenas com o H2.
 */
@RestController
@RequestMapping("/oracle")
@ConditionalOnProperty(name = "smarthas.oracle.enabled", havingValue = "true")
@Tag(name = "Oracle PL/SQL (Fase 6)", description = "Functions e procedures PL/SQL acionadas via JDBC")
@SecurityRequirement(name = "bearerAuth")
public class OraclePlsqlController {

    private final OraclePlsqlService service;

    public OraclePlsqlController(OraclePlsqlService service) {
        this.service = service;
    }

    @GetMapping("/pedidos")
    @Operation(summary = "Pedidos com risco calculado por FN_CALCULA_RISCO / FN_NIVEL_RISCO / FN_RESUMO_PEDIDO")
    public List<OraclePedido> listarPedidos() {
        return service.listarPedidos();
    }

    @GetMapping("/pedidos/busca")
    @Operation(summary = "Busca flexivel com Dynamic SQL (PKG_SH_CONSULTA.FN_BUSCAR_PEDIDOS)",
            description = "Filtros opcionais. ordenarPor: score, prazo, distancia, codigo ou status. direcao: ASC ou DESC.")
    public List<OraclePedido> buscarPedidos(@RequestParam(name = "status", required = false) String status,
                                            @RequestParam(name = "nivel", required = false) String nivel,
                                            @RequestParam(name = "regiao", required = false) String regiao,
                                            @RequestParam(name = "scoreMin", required = false) Integer scoreMin,
                                            @RequestParam(name = "ordenarPor", required = false) String ordenarPor,
                                            @RequestParam(name = "direcao", required = false) String direcao) {
        return service.buscarPedidos(status, nivel, regiao, scoreMin, ordenarPor, direcao);
    }

    @GetMapping("/pedidos/resumo")
    @Operation(summary = "Indicadores agrupados com Dynamic SQL (PKG_SH_CONSULTA.FN_RESUMO_POR_DIMENSAO)",
            description = "dimensao: status, nivel, regiao ou parceiro.")
    public List<OracleResumoPedidos> resumirPedidos(@RequestParam("dimensao") String dimensao) {
        return service.resumirPedidos(dimensao);
    }

    @GetMapping("/pedidos/{id}")
    @Operation(summary = "Pedido do Oracle por ID (view V_SH_PEDIDO_RISCO)")
    public OraclePedido buscarPedido(@PathVariable("id") long id) {
        return service.buscarPedido(id);
    }

    @PostMapping("/entregas/{id}/recalcular-risco")
    @Operation(summary = "Evento de back-end: aciona a procedure SP_RECALCULAR_RISCO (1 IN + 4 OUT)")
    public OracleRiscoLogistico recalcularRisco(@PathVariable("id") long id) {
        return service.recalcularRisco(id);
    }

    @PostMapping("/sensores/{id}/leituras")
    @Operation(summary = "Grava leitura IoT e aciona SP_REGISTRAR_ALERTAS_SENSORES na mesma transacao")
    public ResponseEntity<OracleLeituraRegistrada> registrarLeitura(@PathVariable("id") long idSensor,
                                                                    @RequestBody OracleLeituraRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.registrarLeitura(idSensor, request));
    }

    @GetMapping("/alertas")
    @Operation(summary = "Alertas gerados pelas procedures (filtro opcional: ABERTO/RESOLVIDO)")
    public List<OracleAlerta> listarAlertas(@RequestParam(name = "status", required = false) String status) {
        return service.listarAlertas(status);
    }

    @PostMapping("/alertas/{id}/resolver")
    @Operation(summary = "Encerra o alerta (PKG_SH_IOT.SP_RESOLVER_ALERTA). Exige perfil ADMIN")
    public ResponseEntity<Void> resolverAlerta(@PathVariable("id") long id) {
        service.resolverAlerta(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/alertas/auditoria")
    @Operation(summary = "Trilha gravada pela trigger TRG_SH_ALERTA_AUDITORIA (filtro opcional: alertaId)")
    public List<OracleAuditoriaAlerta> listarAuditoria(@RequestParam(name = "alertaId", required = false) Long alertaId) {
        return service.listarAuditoria(alertaId);
    }

    @PostMapping("/relatorios/usuarios")
    @Operation(summary = "Executa SP_GERAR_RELATORIO_USUARIOS e devolve o snapshot por usuario")
    public List<OracleRelatorioUsuario> gerarRelatorioUsuarios() {
        return service.gerarRelatorioUsuarios();
    }
}
