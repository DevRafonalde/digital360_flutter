package com.smarthas.backend.dto;

import jakarta.validation.constraints.NotBlank;

/** O campo chama-se senhaUser (nao senha) para casar com o ApiService.login() do app Flutter. */
public record LoginRequest(
        @NotBlank(message = "nomeUser e obrigatorio") String nomeUser,
        @NotBlank(message = "senhaUser e obrigatoria") String senhaUser
) {
}
