package com.smarthas.backend.service;

import com.smarthas.backend.dto.FeedbackRequest;
import com.smarthas.backend.model.FeedbackEntrega;
import com.smarthas.backend.repository.FeedbackEntregaRepository;
import org.springframework.stereotype.Service;

@Service
public class FeedbackService {

    private final FeedbackEntregaRepository feedbackRepository;

    public FeedbackService(FeedbackEntregaRepository feedbackRepository) {
        this.feedbackRepository = feedbackRepository;
    }

    public void registrar(FeedbackRequest request) {
        FeedbackEntrega feedback = FeedbackEntrega.builder()
                .pedidoId(request.pedidoId())
                .nota(request.nota())
                .comentario(request.comentario())
                .build();
        feedbackRepository.save(feedback);
    }
}
