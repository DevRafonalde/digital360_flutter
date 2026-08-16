package com.smarthas.backend.controller;

import com.smarthas.backend.dto.GamificacaoResumoResponse;
import com.smarthas.backend.dto.RankingItemResponse;
import com.smarthas.backend.service.GamificacaoService;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@Tag(name = "Gamificacao", description = "Cursos concluidos, sequencia de dias, pontos e ranking")
@SecurityRequirement(name = "bearerAuth")
public class GamificacaoController {

    private final GamificacaoService gamificacaoService;

    public GamificacaoController(GamificacaoService gamificacaoService) {
        this.gamificacaoService = gamificacaoService;
    }

    @GetMapping("/gamificacao/{userId}/resumo")
    public GamificacaoResumoResponse resumo(Authentication authentication, @PathVariable String userId) {
        return gamificacaoService.resumoAutorizado(authentication.getName(), userId);
    }

    @GetMapping("/gamificacao/ranking")
    public List<RankingItemResponse> ranking() {
        return gamificacaoService.ranking();
    }
}
