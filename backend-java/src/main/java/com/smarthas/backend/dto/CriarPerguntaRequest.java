package com.smarthas.backend.dto;

import jakarta.validation.constraints.NotBlank;

public record CriarPerguntaRequest(
        @NotBlank(message = "titulo e obrigatorio") String titulo,
        @NotBlank(message = "corpo e obrigatorio") String corpo
) {
}
