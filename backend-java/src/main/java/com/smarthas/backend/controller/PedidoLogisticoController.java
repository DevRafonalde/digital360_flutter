package com.smarthas.backend.controller;

import com.smarthas.backend.dto.*;
import com.smarthas.backend.service.AssistenteService;
import com.smarthas.backend.service.FeedbackService;
import com.smarthas.backend.service.PedidoLogisticoService;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** AI Logistics Extension: pedidos monitorados, risco de entrega, feedback e assistente. */
@RestController
@Tag(name = "AI Logistics Extension", description = "Pedidos, risco de entrega, feedback e assistente conversacional")
@SecurityRequirement(name = "bearerAuth")
public class PedidoLogisticoController {

    private final PedidoLogisticoService pedidoService;
    private final AssistenteService assistenteService;
    private final FeedbackService feedbackService;

    public PedidoLogisticoController(PedidoLogisticoService pedidoService,
                                      AssistenteService assistenteService,
                                      FeedbackService feedbackService) {
        this.pedidoService = pedidoService;
        this.assistenteService = assistenteService;
        this.feedbackService = feedbackService;
    }

    @GetMapping("/pedidos")
    public List<PedidoLogisticoResponse> listar() {
        return pedidoService.listar().stream().map(PedidoLogisticoResponse::from).toList();
    }

    @GetMapping("/pedidos/{id}")
    public PedidoLogisticoResponse buscar(@PathVariable Long id) {
        return PedidoLogisticoResponse.from(pedidoService.buscar(id));
    }

    @PostMapping("/pedidos")
    public ResponseEntity<PedidoLogisticoResponse> criar(@Valid @RequestBody PedidoLogisticoRequest request) {
        var response = PedidoLogisticoResponse.from(pedidoService.criar(request));
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PutMapping("/pedidos/{id}")
    public PedidoLogisticoResponse atualizar(@PathVariable Long id, @Valid @RequestBody PedidoLogisticoRequest request) {
        return PedidoLogisticoResponse.from(pedidoService.atualizar(id, request));
    }

    @DeleteMapping("/pedidos/{id}")
    public ResponseEntity<Void> remover(@PathVariable Long id) {
        pedidoService.remover(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/entregas/{id}/recalcular-risco")
    public RiscoLogisticoResponse recalcularRisco(
            @PathVariable Long id,
            @RequestBody(required = false) RecalcularRiscoRequest request
    ) {
        int impactoClima = (request != null && request.impactoClima() != null) ? request.impactoClima() : 0;
        return pedidoService.recalcularRisco(id, impactoClima);
    }

    @PostMapping("/pedidos/{id}/reagendar")
    public PedidoLogisticoResponse reagendar(@PathVariable Long id) {
        return PedidoLogisticoResponse.from(pedidoService.reagendar(id));
    }

    @PostMapping("/feedback-entrega")
    public ResponseEntity<Void> enviarFeedback(@Valid @RequestBody FeedbackRequest request) {
        feedbackService.registrar(request);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @PostMapping("/assistente-logistico/pergunta")
    public RespostaAssistente perguntar(@Valid @RequestBody PerguntaRequest request) {
        return assistenteService.responder(request.pergunta());
    }
}
