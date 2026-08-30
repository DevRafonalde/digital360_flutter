package com.smarthas.backend.dto;

import java.time.LocalDateTime;
import java.util.List;

public record PerguntaForumResponse(
        Long id,
        String autorNome,
        String titulo,
        String corpo,
        LocalDateTime criadoEm,
        Long totalRespostas,
        List<RespostaForumResponse> respostas
) {
}
