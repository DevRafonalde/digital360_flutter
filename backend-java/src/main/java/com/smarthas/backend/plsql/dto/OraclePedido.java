package com.smarthas.backend.plsql.dto;

/**
 * Pedido monitorado pela AI Logistics Extension, lido da view V_SH_PEDIDO_RISCO.
 * Os nomes dos campos seguem o contrato ja consumido pelo app Flutter
 * (PedidoLogistico.fromJson), acrescidos dos campos calculados no Oracle.
 */
public record OraclePedido(
        long id,
        String codigoPedido,
        String produto,
        String tipoProduto,
        String regiaoEntrega,
        int distanciaKm,
        String prazoPrometido,
        String statusAtual,
        String parceiroLogistico,
        boolean estoqueDisponivel,
        int historicoAtrasos,
        int reagendamentos,
        double latitude,
        double longitude,
        int riscoScore,      // FN_CALCULA_RISCO
        String riscoNivel,   // FN_NIVEL_RISCO
        String resumo        // FN_RESUMO_PEDIDO
) {
}
