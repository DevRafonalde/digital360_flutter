package com.smarthas.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record EventoRequest(
        @NotBlank(message = "tipo e obrigatorio") String tipo,
        @NotNull(message = "referenceId e obrigatorio") Long referenceId,
        String categoria
) {
}
