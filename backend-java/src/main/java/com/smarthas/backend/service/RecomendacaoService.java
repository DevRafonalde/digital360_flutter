package com.smarthas.backend.service;

import com.smarthas.backend.dto.ItemRecomendado;
import com.smarthas.backend.exception.ApiException;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class RecomendacaoService {

    private final EventoService eventoService;
    private final RecomendacaoEngine recomendacaoEngine;

    public RecomendacaoService(EventoService eventoService, RecomendacaoEngine recomendacaoEngine) {
        this.eventoService = eventoService;
        this.recomendacaoEngine = recomendacaoEngine;
    }

    /** Espelha a checagem de autorizacao do Python: so pode ver as proprias recomendacoes. */
    public List<ItemRecomendado> recomendarPara(String usuarioAutenticado, String userIdSolicitado) {
        if (!usuarioAutenticado.equals(userIdSolicitado)) {
            throw ApiException.forbidden("Voce so pode consultar suas proprias recomendacoes");
        }
        return recomendacaoEngine.recomendar(userIdSolicitado, eventoService.listarTodos());
    }
}
