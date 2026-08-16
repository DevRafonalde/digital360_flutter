package com.smarthas.backend.controller;

import com.smarthas.backend.dto.ItemRecomendado;
import com.smarthas.backend.service.RecomendacaoService;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@Tag(name = "Recomendacoes", description = "Top recomendacoes heuristicas para o usuario (so as proprias)")
@SecurityRequirement(name = "bearerAuth")
public class RecomendacaoController {

    private final RecomendacaoService recomendacaoService;

    public RecomendacaoController(RecomendacaoService recomendacaoService) {
        this.recomendacaoService = recomendacaoService;
    }

    @GetMapping("/recomendacoes/{userId}")
    public List<ItemRecomendado> recomendacoes(Authentication authentication, @PathVariable String userId) {
        return recomendacaoService.recomendarPara(authentication.getName(), userId);
    }
}
