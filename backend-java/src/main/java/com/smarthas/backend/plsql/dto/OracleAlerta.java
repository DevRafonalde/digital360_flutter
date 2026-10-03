package com.smarthas.backend.plsql.dto;

/** Alerta gravado em T_SH_ALERTA (origem SENSOR ou RISCO). */
public record OracleAlerta(
        long id,
        long pedidoId,
        String codigoPedido,
        String origem,
        String nivel,
        String mensagem,
        String dataHora,
        String status
) {
}
