package com.smarthas.backend.dto;

public record ResumoIdosoResponse(
        String idosoNome,
        Integer cursosConcluidos,
        Integer sequenciaDias,
        Integer pontos
) {
}
