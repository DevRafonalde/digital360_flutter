package com.smarthas.backend.dto;

import java.time.LocalDateTime;

public record AvaliacaoCursoResponse(
        Long id,
        String usuarioNome,
        Integer nota,
        String comentario,
        LocalDateTime criadoEm
) {
}
