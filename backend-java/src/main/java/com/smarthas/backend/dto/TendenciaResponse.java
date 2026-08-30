package com.smarthas.backend.dto;

public record TendenciaResponse(
        String categoria,
        Integer volumeUltimos7Dias,
        Double mediaHistoricaDiaria,
        Boolean emAlta
) {
}
