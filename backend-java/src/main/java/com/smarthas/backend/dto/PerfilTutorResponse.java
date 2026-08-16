package com.smarthas.backend.dto;

import java.util.List;

public record PerfilTutorResponse(
        String nomeAmigavel,
        Integer totalCursos,
        List<CursoResponse> cursos,
        Double mediaAvaliacao,
        Integer totalAvaliacoes
) {
}
