package com.smarthas.backend.dto;

import jakarta.validation.constraints.NotBlank;

/** codigoIdoso e o proprio nomeUser do idoso (ja unico, sem cadastro de codigo separado). */
public record VincularCuidadorRequest(
        @NotBlank(message = "codigoIdoso e obrigatorio") String codigoIdoso
) {
}
