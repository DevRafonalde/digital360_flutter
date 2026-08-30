package com.smarthas.backend.controller;

import com.smarthas.backend.dto.IndicacoesResponse;
import com.smarthas.backend.dto.TornarTutorResponse;
import com.smarthas.backend.service.PerfilService;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@Tag(name = "Perfil", description = "Virar tutor, indicacoes e exclusao da propria conta (LGPD)")
@SecurityRequirement(name = "bearerAuth")
public class PerfilController {

    private final PerfilService perfilService;

    public PerfilController(PerfilService perfilService) {
        this.perfilService = perfilService;
    }

    @PostMapping("/perfil/tornar-tutor")
    public TornarTutorResponse tornarTutor(Authentication authentication) {
        return new TornarTutorResponse(perfilService.tornarTutor(authentication.getName()));
    }

    @GetMapping("/indicacoes/minhas")
    public IndicacoesResponse minhasIndicacoes(Authentication authentication) {
        return perfilService.minhasIndicacoes(authentication.getName());
    }

    @DeleteMapping("/perfil/conta")
    public ResponseEntity<Void> excluirConta(Authentication authentication) {
        perfilService.excluirConta(authentication.getName());
        return ResponseEntity.noContent().build();
    }
}
