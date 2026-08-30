package com.smarthas.backend.dto;

import jakarta.validation.constraints.NotBlank;

public record ServicoRequest(
        @NotBlank(message = "titulo e obrigatorio") String titulo,
        @NotBlank(message = "descricao e obrigatoria") String descricao,
        @NotBlank(message = "categoria e obrigatoria") String categoria,
        @NotBlank(message = "orgao e obrigatorio") String orgao,
        @NotBlank(message = "conteudo e obrigatorio") String conteudo
) {
}
