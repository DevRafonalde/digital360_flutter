package com.smarthas.backend.controller;

import com.smarthas.backend.dto.TendenciaResponse;
import com.smarthas.backend.service.TendenciaService;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@Tag(name = "Tendencias", description = "Deteccao de picos/sazonalidade por categoria")
@SecurityRequirement(name = "bearerAuth")
public class TendenciaController {

    private final TendenciaService tendenciaService;

    public TendenciaController(TendenciaService tendenciaService) {
        this.tendenciaService = tendenciaService;
    }

    @GetMapping("/tendencias")
    public List<TendenciaResponse> tendencias() {
        return tendenciaService.detectar();
    }
}
