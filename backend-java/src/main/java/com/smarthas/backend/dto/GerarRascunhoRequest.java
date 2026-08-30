package com.smarthas.backend.dto;

import jakarta.validation.constraints.NotBlank;

public record GerarRascunhoRequest(
        @NotBlank(message = "titulo e obrigatorio") String titulo,
        String nivel
) {
}
