package com.smarthas.backend.dto;

import com.smarthas.backend.model.Usuario;

/** Espelha exatamente Usuario.fromJson() do app Flutter/Kotlin. */
public record LoginResponse(
        Long id,
        String nomeAmigavel,
        String nomeUser,
        String accessToken,
        String refreshToken,
        String cpf,
        String nomeCompleto,
        Boolean isTutor
) {
    public static LoginResponse from(Usuario usuario, String accessToken, String refreshToken) {
        return new LoginResponse(
                usuario.getId(), usuario.getNomeAmigavel(), usuario.getNomeUser(),
                accessToken, refreshToken, usuario.getCpf(), usuario.getNomeCompleto(), usuario.getIsTutor()
        );
    }
}
