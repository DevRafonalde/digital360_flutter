package com.smarthas.backend.service;

import com.smarthas.backend.dto.*;
import com.smarthas.backend.exception.ApiException;
import com.smarthas.backend.model.PerguntaForum;
import com.smarthas.backend.model.RespostaForum;
import com.smarthas.backend.model.Usuario;
import com.smarthas.backend.repository.PerguntaForumRepository;
import com.smarthas.backend.repository.RespostaForumRepository;
import com.smarthas.backend.repository.UsuarioRepository;
import org.springframework.stereotype.Service;

import java.util.List;

/** Forum de perguntas e respostas da comunidade, aberto a qualquer usuario autenticado. */
@Service
public class ForumService {

    private static final String AUTOR_ANONIMO = "Anônimo";

    private final PerguntaForumRepository perguntaRepository;
    private final RespostaForumRepository respostaRepository;
    private final UsuarioRepository usuarioRepository;

    public ForumService(PerguntaForumRepository perguntaRepository, RespostaForumRepository respostaRepository,
                         UsuarioRepository usuarioRepository) {
        this.perguntaRepository = perguntaRepository;
        this.respostaRepository = respostaRepository;
        this.usuarioRepository = usuarioRepository;
    }

    public PerguntaForumResponse criarPergunta(String autorNomeUser, CriarPerguntaRequest request) {
        Usuario autor = buscarUsuario(autorNomeUser);
        PerguntaForum pergunta = perguntaRepository.save(PerguntaForum.builder()
                .autorId(autor.getId())
                .titulo(request.titulo())
                .corpo(request.corpo())
                .build());
        return paraResponse(pergunta, 0, null);
    }

    public List<PerguntaForumResponse> listarPerguntas() {
        return perguntaRepository.findAllByOrderByCriadoEmDesc().stream()
                .map(p -> paraResponse(p, respostaRepository.countByPerguntaId(p.getId()), null))
                .toList();
    }

    public PerguntaForumResponse detalhe(Long perguntaId) {
        PerguntaForum pergunta = perguntaRepository.findById(perguntaId)
                .orElseThrow(() -> ApiException.notFound("Pergunta nao encontrada"));
        List<RespostaForumResponse> respostas = respostaRepository.findByPerguntaIdOrderByCriadoEm(perguntaId).stream()
                .map(this::paraResponseResposta)
                .toList();
        return paraResponse(pergunta, respostas.size(), respostas);
    }

    public PerguntaForumResponse responder(Long perguntaId, String autorNomeUser, CriarRespostaRequest request) {
        if (!perguntaRepository.existsById(perguntaId)) {
            throw ApiException.notFound("Pergunta nao encontrada");
        }
        Usuario autor = buscarUsuario(autorNomeUser);
        respostaRepository.save(RespostaForum.builder()
                .perguntaId(perguntaId)
                .autorId(autor.getId())
                .corpo(request.corpo())
                .build());
        return detalhe(perguntaId);
    }

    private PerguntaForumResponse paraResponse(PerguntaForum p, long totalRespostas, List<RespostaForumResponse> respostas) {
        return new PerguntaForumResponse(p.getId(), nomeAutor(p.getAutorId()), p.getTitulo(), p.getCorpo(),
                p.getCriadoEm(), totalRespostas, respostas);
    }

    private RespostaForumResponse paraResponseResposta(RespostaForum r) {
        return new RespostaForumResponse(r.getId(), nomeAutor(r.getAutorId()), r.getCorpo(), r.getCriadoEm());
    }

    private String nomeAutor(Long autorId) {
        if (autorId == null) return AUTOR_ANONIMO;
        return usuarioRepository.findById(autorId).map(Usuario::getNomeAmigavel).orElse(AUTOR_ANONIMO);
    }

    private Usuario buscarUsuario(String nomeUser) {
        return usuarioRepository.findByNomeUser(nomeUser)
                .orElseThrow(() -> ApiException.notFound("Usuario nao encontrado: " + nomeUser));
    }
}
