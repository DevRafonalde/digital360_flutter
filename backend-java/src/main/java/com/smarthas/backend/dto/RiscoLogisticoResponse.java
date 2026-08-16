package com.smarthas.backend.dto;

/** Espelha exatamente RiscoLogistico.fromJson() do app Flutter/Kotlin. */
public record RiscoLogisticoResponse(
        Long pedidoId,
        Integer riscoScore,
        String riscoNivel,
        String recomendacao,
        String mensagemCliente
) {
}
