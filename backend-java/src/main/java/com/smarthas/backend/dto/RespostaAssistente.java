package com.smarthas.backend.dto;

/** Espelha o Map<String,String> {resposta, acaoRecomendada} lido pelo app Flutter. */
public record RespostaAssistente(
        String resposta,
        String acaoRecomendada
) {
}
