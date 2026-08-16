package com.smarthas.backend.dto;

import com.smarthas.backend.model.PedidoLogistico;

/** Espelha exatamente PedidoLogistico.fromJson() do app Flutter/Kotlin. */
public record PedidoLogisticoResponse(
        Long id,
        String codigoPedido,
        String produto,
        String tipoProduto,
        String regiaoEntrega,
        Integer distanciaKm,
        String prazoPrometido,
        String statusAtual,
        String parceiroLogistico,
        Boolean estoqueDisponivel,
        Integer historicoAtrasos,
        Integer reagendamentos,
        Double latitude,
        Double longitude
) {
    public static PedidoLogisticoResponse from(PedidoLogistico p) {
        return new PedidoLogisticoResponse(
                p.getId(), p.getCodigoPedido(), p.getProduto(), p.getTipoProduto(),
                p.getRegiaoEntrega(), p.getDistanciaKm(), p.getPrazoPrometido(), p.getStatusAtual(),
                p.getParceiroLogistico(), p.getEstoqueDisponivel(), p.getHistoricoAtrasos(),
                p.getReagendamentos(), p.getLatitude(), p.getLongitude()
        );
    }
}
