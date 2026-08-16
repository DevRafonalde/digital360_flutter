package com.smarthas.backend.service;

import com.smarthas.backend.dto.TendenciaResponse;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class TendenciaService {

    private final EventoService eventoService;
    private final TendenciaEngine tendenciaEngine;

    public TendenciaService(EventoService eventoService, TendenciaEngine tendenciaEngine) {
        this.eventoService = eventoService;
        this.tendenciaEngine = tendenciaEngine;
    }

    public List<TendenciaResponse> detectar() {
        return tendenciaEngine.detectar(eventoService.listarTodos());
    }
}
