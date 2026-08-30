package com.smarthas.backend.service;

import com.smarthas.backend.dto.EventoRequest;
import com.smarthas.backend.model.Evento;
import com.smarthas.backend.repository.EventoRepository;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Registra e le eventos de uso (curso/servico visitado, ou "curso_concluido"
 * para gamificacao) - alimenta recomendacao, tendencias e gamificacao.
 */
@Service
public class EventoService {

    private final EventoRepository eventoRepository;

    public EventoService(EventoRepository eventoRepository) {
        this.eventoRepository = eventoRepository;
    }

    public long registrar(String nomeUser, EventoRequest request) {
        eventoRepository.save(Evento.builder()
                .userId(nomeUser)
                .tipo(request.tipo())
                .referenceId(request.referenceId())
                .categoria(request.categoria())
                .build());
        return eventoRepository.count();
    }

    public List<Evento> listarTodos() {
        return eventoRepository.findAll();
    }

    public List<Evento> listarPorUsuario(String nomeUser) {
        return eventoRepository.findByUserId(nomeUser);
    }
}
