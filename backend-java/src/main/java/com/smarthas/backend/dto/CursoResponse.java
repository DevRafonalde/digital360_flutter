package com.smarthas.backend.dto;

import com.smarthas.backend.model.Curso;

import java.util.List;

/** Espelha exatamente Curso.fromJson() do app Flutter/Kotlin. */
public record CursoResponse(
        Long id,
        String titulo,
        String descricao,
        String nivel,
        Integer cargaHoraria,
        Integer totalModulos,
        Integer progresso,
        String autorId,
        String origem,
        String status,
        List<String> topicosModulos
) {
    public static CursoResponse from(Curso c, String autorNomeUser) {
        return new CursoResponse(
                c.getId(), c.getTitulo(), c.getDescricao(), c.getNivel(),
                c.getCargaHoraria(), c.getTotalModulos(), c.getProgresso(),
                autorNomeUser, c.getOrigem(), c.getStatus(), c.getTopicosModulos()
        );
    }
}
