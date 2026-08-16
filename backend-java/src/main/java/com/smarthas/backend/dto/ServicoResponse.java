package com.smarthas.backend.dto;

import com.smarthas.backend.model.Servico;

/** Espelha exatamente Servico.fromJson() do app Flutter/Kotlin. */
public record ServicoResponse(
        Long id,
        String titulo,
        String descricao,
        String categoria,
        String orgao,
        String conteudo
) {
    public static ServicoResponse from(Servico s) {
        return new ServicoResponse(
                s.getId(), s.getTitulo(), s.getDescricao(), s.getCategoria(), s.getOrgao(), s.getConteudo()
        );
    }
}
