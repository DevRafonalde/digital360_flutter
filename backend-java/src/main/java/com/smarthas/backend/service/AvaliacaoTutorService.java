package com.smarthas.backend.service;

import com.smarthas.backend.dto.*;
import com.smarthas.backend.exception.ApiException;
import com.smarthas.backend.model.AvaliacaoCurso;
import com.smarthas.backend.model.Curso;
import com.smarthas.backend.model.Usuario;
import com.smarthas.backend.repository.AvaliacaoCursoRepository;
import com.smarthas.backend.repository.CursoRepository;
import com.smarthas.backend.repository.UsuarioRepository;
import org.springframework.stereotype.Service;

import java.util.List;

/** Marketplace de tutores: avaliacao de cursos e perfil publico do tutor. */
@Service
public class AvaliacaoTutorService {

    private static final String AUTOR_ANONIMO = "Anônimo";

    private final AvaliacaoCursoRepository avaliacaoRepository;
    private final CursoRepository cursoRepository;
    private final UsuarioRepository usuarioRepository;

    public AvaliacaoTutorService(AvaliacaoCursoRepository avaliacaoRepository, CursoRepository cursoRepository,
                                  UsuarioRepository usuarioRepository) {
        this.avaliacaoRepository = avaliacaoRepository;
        this.cursoRepository = cursoRepository;
        this.usuarioRepository = usuarioRepository;
    }

    public AvaliacaoCursoResponse avaliar(Long cursoId, String usuarioNomeUser, AvaliarCursoRequest request) {
        if (!cursoRepository.existsById(cursoId)) {
            throw ApiException.notFound("Curso nao encontrado");
        }
        Usuario usuario = usuarioRepository.findByNomeUser(usuarioNomeUser)
                .orElseThrow(() -> ApiException.notFound("Usuario nao encontrado"));

        AvaliacaoCurso avaliacao = avaliacaoRepository.save(AvaliacaoCurso.builder()
                .cursoId(cursoId)
                .usuarioId(usuario.getId())
                .nota(request.nota())
                .comentario(request.comentario())
                .build());

        return paraResponse(avaliacao);
    }

    public List<AvaliacaoCursoResponse> listarAvaliacoes(Long cursoId) {
        return avaliacaoRepository.findByCursoId(cursoId).stream().map(this::paraResponse).toList();
    }

    public PerfilTutorResponse perfilTutor(String autorNomeUser) {
        Usuario tutor = usuarioRepository.findByNomeUser(autorNomeUser)
                .filter(Usuario::getIsTutor)
                .orElseThrow(() -> ApiException.notFound("Tutor nao encontrado"));

        List<Curso> cursos = cursoRepository.findByAutorIdAndStatus(tutor.getId(), "PUBLICADO");
        List<Integer> notas = cursos.stream()
                .flatMap(c -> avaliacaoRepository.findByCursoId(c.getId()).stream())
                .map(AvaliacaoCurso::getNota)
                .toList();

        Double media = notas.isEmpty() ? null :
                Math.round((notas.stream().mapToInt(Integer::intValue).average().orElse(0)) * 10.0) / 10.0;

        List<CursoResponse> cursosResponse = cursos.stream()
                .map(c -> CursoResponse.from(c, tutor.getNomeUser()))
                .toList();

        return new PerfilTutorResponse(tutor.getNomeAmigavel(), cursos.size(), cursosResponse, media, notas.size());
    }

    private AvaliacaoCursoResponse paraResponse(AvaliacaoCurso a) {
        String nomeUsuario = a.getUsuarioId() == null ? AUTOR_ANONIMO :
                usuarioRepository.findById(a.getUsuarioId()).map(Usuario::getNomeAmigavel).orElse(AUTOR_ANONIMO);
        return new AvaliacaoCursoResponse(a.getId(), nomeUsuario, a.getNota(), a.getComentario(), a.getCriadoEm());
    }
}
