package com.smarthas.backend.dto;

import jakarta.validation.constraints.NotBlank;

import java.util.List;

/**
 * Serve dois fluxos com o mesmo corpo, como no backend Python:
 * - Catalogo oficial (dashboard, ADMIN): normalmente informa totalModulos.
 * - Curso comunitario (app, tutor): informa topicosModulos; totalModulos e
 *   derivado de topicosModulos.size() quando nao enviado.
 */
public record CursoRequest(
        @NotBlank(message = "titulo e obrigatorio") String titulo,
        @NotBlank(message = "descricao e obrigatoria") String descricao,
        @NotBlank(message = "nivel e obrigatorio") String nivel,
        Integer cargaHoraria,
        Integer totalModulos,
        List<String> topicosModulos
) {
}
