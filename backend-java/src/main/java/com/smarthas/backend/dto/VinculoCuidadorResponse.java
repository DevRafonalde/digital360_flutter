package com.smarthas.backend.dto;

import java.time.LocalDateTime;

public record VinculoCuidadorResponse(
        String idosoId,
        String idosoNome,
        LocalDateTime vinculadoEm
) {
}
