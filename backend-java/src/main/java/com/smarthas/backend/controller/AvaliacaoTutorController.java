package com.smarthas.backend.controller;

import com.smarthas.backend.dto.AvaliacaoCursoResponse;
import com.smarthas.backend.dto.AvaliarCursoRequest;
import com.smarthas.backend.dto.PerfilTutorResponse;
import com.smarthas.backend.service.AvaliacaoTutorService;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@Tag(name = "Marketplace de tutores", description = "Avaliacao de cursos e perfil publico do tutor")
@SecurityRequirement(name = "bearerAuth")
public class AvaliacaoTutorController {

    private final AvaliacaoTutorService avaliacaoTutorService;

    public AvaliacaoTutorController(AvaliacaoTutorService avaliacaoTutorService) {
        this.avaliacaoTutorService = avaliacaoTutorService;
    }

    @PostMapping("/cursos/{id}/avaliar")
    public ResponseEntity<AvaliacaoCursoResponse> avaliar(
            Authentication authentication, @PathVariable("id") Long cursoId, @Valid @RequestBody AvaliarCursoRequest request
    ) {
        var avaliacao = avaliacaoTutorService.avaliar(cursoId, authentication.getName(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(avaliacao);
    }

    @GetMapping("/cursos/{id}/avaliacoes")
    public List<AvaliacaoCursoResponse> avaliacoes(@PathVariable("id") Long cursoId) {
        return avaliacaoTutorService.listarAvaliacoes(cursoId);
    }

    @GetMapping("/tutores/{autorId}")
    public PerfilTutorResponse perfilTutor(@PathVariable String autorId) {
        return avaliacaoTutorService.perfilTutor(autorId);
    }
}
