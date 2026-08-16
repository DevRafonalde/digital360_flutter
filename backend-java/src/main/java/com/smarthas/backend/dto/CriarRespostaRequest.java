package com.smarthas.backend.dto;

import jakarta.validation.constraints.NotBlank;

public record CriarRespostaRequest(
        @NotBlank(message = "corpo e obrigatorio") String corpo
) {
}
