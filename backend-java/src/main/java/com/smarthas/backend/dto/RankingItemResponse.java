package com.smarthas.backend.dto;

public record RankingItemResponse(
        String nomeAmigavel,
        Integer cursosConcluidos,
        Integer sequenciaDias,
        Integer pontos
) {
}
