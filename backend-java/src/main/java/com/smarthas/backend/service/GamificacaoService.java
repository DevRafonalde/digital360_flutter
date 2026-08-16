package com.smarthas.backend.service;

import com.smarthas.backend.dto.GamificacaoResumoResponse;
import com.smarthas.backend.dto.RankingItemResponse;
import com.smarthas.backend.exception.ApiException;
import com.smarthas.backend.model.Evento;
import com.smarthas.backend.repository.EventoRepository;
import com.smarthas.backend.repository.UsuarioRepository;
import org.springframework.stereotype.Service;

import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class GamificacaoService {

    private final EventoRepository eventoRepository;
    private final UsuarioRepository usuarioRepository;
    private final GamificacaoEngine gamificacaoEngine;

    public GamificacaoService(EventoRepository eventoRepository, UsuarioRepository usuarioRepository,
                               GamificacaoEngine gamificacaoEngine) {
        this.eventoRepository = eventoRepository;
        this.usuarioRepository = usuarioRepository;
        this.gamificacaoEngine = gamificacaoEngine;
    }

    public GamificacaoResumoResponse resumoDe(String nomeUser) {
        List<Evento> eventos = eventoRepository.findByUserId(nomeUser);

        Set<Long> cursosConcluidos = eventos.stream()
                .filter(e -> "curso_concluido".equals(e.getTipo()))
                .map(Evento::getReferenceId)
                .collect(Collectors.toSet());

        int sequencia = gamificacaoEngine.calcularSequenciaDias(eventos.stream().map(Evento::getTimestamp).toList());
        int pontos = cursosConcluidos.size() * 100 + sequencia * 10;

        return new GamificacaoResumoResponse(cursosConcluidos.size(), sequencia, pontos);
    }

    public GamificacaoResumoResponse resumoAutorizado(String usuarioAutenticado, String userIdSolicitado) {
        if (!usuarioAutenticado.equals(userIdSolicitado)) {
            throw ApiException.forbidden("Voce so pode consultar seu proprio resumo");
        }
        return resumoDe(userIdSolicitado);
    }

    public List<RankingItemResponse> ranking() {
        return usuarioRepository.findAll().stream()
                .map(u -> Map.entry(u, resumoDe(u.getNomeUser())))
                .filter(e -> e.getValue().pontos() > 0)
                .map(e -> new RankingItemResponse(
                        e.getKey().getNomeAmigavel(),
                        e.getValue().cursosConcluidos(),
                        e.getValue().sequenciaDias(),
                        e.getValue().pontos()))
                .sorted(Comparator.comparingInt(RankingItemResponse::pontos).reversed())
                .limit(10)
                .toList();
    }
}
