package com.smarthas.backend.dto;

public record MetricasImpactoResponse(
        Long totalUsuarios,
        Long totalCursosConcluidos,
        Long totalCursosPublicados,
        Long totalCursosComunidade,
        Long totalPerguntasForum,
        String observacao
) {
}
