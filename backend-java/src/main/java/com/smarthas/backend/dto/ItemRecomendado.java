package com.smarthas.backend.dto;

/**
 * Item do catalogo pontuado pelo motor de recomendacao. Campos opcionais
 * (nivel/categoria/motivo/diasDesdeUltimaVisita) ficam nulos conforme o caso
 * (cold-start x historico), igual ao dict dinamico devolvido pelo Python.
 */
public record ItemRecomendado(
        String tipo,
        Long id,
        String titulo,
        String nivel,
        String categoria,
        Integer score,
        String motivo,
        Integer diasDesdeUltimaVisita
) {
}
