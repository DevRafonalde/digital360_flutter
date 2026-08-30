package com.smarthas.backend.service;

import com.smarthas.backend.dto.MetricasImpactoResponse;
import com.smarthas.backend.repository.CursoRepository;
import com.smarthas.backend.repository.EventoRepository;
import com.smarthas.backend.repository.PerguntaForumRepository;
import com.smarthas.backend.repository.UsuarioRepository;
import org.springframework.stereotype.Service;

/** Painel de impacto: numeros da base ATUAL/demo, nao uma alegacao de escala real. */
@Service
public class MetricasImpactoService {

    private final UsuarioRepository usuarioRepository;
    private final EventoRepository eventoRepository;
    private final CursoRepository cursoRepository;
    private final PerguntaForumRepository perguntaForumRepository;

    public MetricasImpactoService(UsuarioRepository usuarioRepository, EventoRepository eventoRepository,
                                   CursoRepository cursoRepository, PerguntaForumRepository perguntaForumRepository) {
        this.usuarioRepository = usuarioRepository;
        this.eventoRepository = eventoRepository;
        this.cursoRepository = cursoRepository;
        this.perguntaForumRepository = perguntaForumRepository;
    }

    public MetricasImpactoResponse calcular() {
        return new MetricasImpactoResponse(
                usuarioRepository.count(),
                eventoRepository.countByTipo("curso_concluido"),
                cursoRepository.countByStatus("PUBLICADO"),
                cursoRepository.countByOrigem("COMUNIDADE"),
                perguntaForumRepository.count(),
                "Números da base de dados atual (ambiente de demonstração), não uma métrica de escala real."
        );
    }
}
