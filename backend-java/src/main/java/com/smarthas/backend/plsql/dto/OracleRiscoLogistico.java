package com.smarthas.backend.plsql.dto;

/**
 * Resultado da procedure SP_RECALCULAR_RISCO (parametros OUT).
 * Mesmo contrato do RiscoLogistico.fromJson do app Flutter.
 */
public record OracleRiscoLogistico(
        long pedidoId,
        int riscoScore,
        String riscoNivel,
        String recomendacao,
        String mensagemCliente
) {
}
