package com.smarthas.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record PerguntaRequest(
        @NotNull(message = "pedidoId e obrigatorio") Long pedidoId,
        @NotBlank(message = "pergunta e obrigatoria") String pergunta
) {
}
