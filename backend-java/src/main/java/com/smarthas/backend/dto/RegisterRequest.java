package com.smarthas.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * Espelha o RegistrarBody do backend Python (mesmos nomes de campo), incluindo
 * o aceite obrigatorio da politica de privacidade (LGPD) e o codigo de
 * indicacao opcional (credita quem indicou).
 */
public record RegisterRequest(
        @NotBlank(message = "nomeUser e obrigatorio") String nomeUser,
        @NotBlank(message = "senhaUser e obrigatoria")
        @Size(min = 6, message = "senhaUser deve ter ao menos 6 caracteres") String senhaUser,
        String nomeAmigavel,
        String nomeCompleto,
        String cpf,
        @NotNull(message = "aceitouPolitica e obrigatorio") Boolean aceitouPolitica,
        String codigoIndicacao
) {
}
