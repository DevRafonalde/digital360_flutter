package com.smarthas.backend.service;

import com.smarthas.backend.dto.CursoRequest;
import com.smarthas.backend.exception.ApiException;
import com.smarthas.backend.model.Curso;
import com.smarthas.backend.model.Usuario;
import com.smarthas.backend.repository.CursoRepository;
import com.smarthas.backend.repository.UsuarioRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class CursoService {

    private final CursoRepository cursoRepository;
    private final UsuarioRepository usuarioRepository;
    private final RascunhoCursoEngine rascunhoCursoEngine;

    public CursoService(CursoRepository cursoRepository, UsuarioRepository usuarioRepository,
                         RascunhoCursoEngine rascunhoCursoEngine) {
        this.cursoRepository = cursoRepository;
        this.usuarioRepository = usuarioRepository;
        this.rascunhoCursoEngine = rascunhoCursoEngine;
    }

    /** Espelha o GET /cursos do Python: so cursos publicados (rascunhos ficam de fora). */
    public List<Curso> listarPublicados() {
        return cursoRepository.findByStatus("PUBLICADO");
    }

    public Curso buscar(Long id) {
        return cursoRepository.findById(id)
                .orElseThrow(() -> ApiException.notFound("Curso nao encontrado: " + id));
    }

    /**
     * Um unico endpoint (POST /cursos) serve dois papeis, como no app real:
     * ADMIN cadastra curso oficial pelo dashboard; um usuario com isTutor=true
     * publica um curso comunitario. Qualquer outro usuario recebe 403.
     */
    public Curso criar(String nomeUser, boolean isAdmin, CursoRequest request) {
        if (isAdmin) {
            return cursoRepository.save(Curso.builder()
                    .titulo(request.titulo())
                    .descricao(request.descricao())
                    .nivel(request.nivel())
                    .cargaHoraria(request.cargaHoraria() != null ? request.cargaHoraria() : 0)
                    .totalModulos(request.totalModulos() != null ? request.totalModulos()
                            : tamanho(request.topicosModulos()))
                    .topicosModulos(request.topicosModulos() != null ? request.topicosModulos() : List.of())
                    .origem("OFICIAL")
                    .status("PUBLICADO")
                    .progresso(0)
                    .build());
        }

        Usuario tutor = buscarUsuario(nomeUser);
        exigirTutor(tutor);

        List<String> topicos = request.topicosModulos() != null ? request.topicosModulos() : List.of();
        return cursoRepository.save(Curso.builder()
                .titulo(request.titulo())
                .descricao(request.descricao())
                .nivel(request.nivel())
                .cargaHoraria(request.cargaHoraria() != null ? request.cargaHoraria() : 0)
                .totalModulos(topicos.size())
                .topicosModulos(topicos)
                .autorId(tutor.getId())
                .origem("COMUNIDADE")
                .status("PUBLICADO")
                .progresso(0)
                .build());
    }

    public Curso atualizar(Long id, CursoRequest request) {
        Curso curso = buscar(id);
        curso.setTitulo(request.titulo());
        curso.setDescricao(request.descricao());
        curso.setNivel(request.nivel());
        curso.setCargaHoraria(request.cargaHoraria() != null ? request.cargaHoraria() : curso.getCargaHoraria());
        curso.setTotalModulos(request.totalModulos() != null ? request.totalModulos() : curso.getTotalModulos());
        return cursoRepository.save(curso);
    }

    public void remover(Long id) {
        if (!cursoRepository.existsById(id)) {
            throw ApiException.notFound("Curso nao encontrado: " + id);
        }
        cursoRepository.deleteById(id);
    }

    public List<String> gerarRascunho(String nomeUser, String titulo, String nivel) {
        exigirTutor(buscarUsuario(nomeUser));
        return rascunhoCursoEngine.gerar(titulo, nivel);
    }

    public List<Curso> meusCursos(String nomeUser) {
        Usuario usuario = buscarUsuario(nomeUser);
        return cursoRepository.findByAutorId(usuario.getId());
    }

    /** Resolve o autorId (Long) de um curso para o nomeUser exibido no contrato da API. */
    public String resolverAutorNomeUser(Curso curso) {
        if (curso.getAutorId() == null) return null;
        return usuarioRepository.findById(curso.getAutorId()).map(Usuario::getNomeUser).orElse(null);
    }

    private void exigirTutor(Usuario usuario) {
        if (!Boolean.TRUE.equals(usuario.getIsTutor())) {
            throw ApiException.forbidden("Recurso disponivel apenas para tutores");
        }
    }

    private Usuario buscarUsuario(String nomeUser) {
        return usuarioRepository.findByNomeUser(nomeUser)
                .orElseThrow(() -> ApiException.notFound("Usuario nao encontrado: " + nomeUser));
    }

    private int tamanho(List<String> lista) {
        return lista == null ? 0 : lista.size();
    }
}
