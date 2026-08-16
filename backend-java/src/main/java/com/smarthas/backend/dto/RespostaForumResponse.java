package com.smarthas.backend.dto;

import java.time.LocalDateTime;

public record RespostaForumResponse(
        Long id,
        String autorNome,
        String corpo,
        LocalDateTime criadoEm
) {
}
