package com.smarthas.backend.controller;

import com.smarthas.backend.dto.EventoRequest;
import com.smarthas.backend.dto.StatusContagemResponse;
import com.smarthas.backend.service.EventoService;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
@Tag(name = "Eventos", description = "Registro de uso: alimenta recomendacao, tendencias e gamificacao")
@SecurityRequirement(name = "bearerAuth")
public class EventoController {

    private final EventoService eventoService;

    public EventoController(EventoService eventoService) {
        this.eventoService = eventoService;
    }

    @PostMapping("/eventos")
    public ResponseEntity<StatusContagemResponse> registrar(Authentication authentication, @Valid @RequestBody EventoRequest request) {
        long total = eventoService.registrar(authentication.getName(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(new StatusContagemResponse("registrado", total));
    }
}
