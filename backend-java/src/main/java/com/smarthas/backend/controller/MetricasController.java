package com.smarthas.backend.controller;

import com.smarthas.backend.dto.MetricasImpactoResponse;
import com.smarthas.backend.service.MetricasImpactoService;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@Tag(name = "Metricas", description = "Painel de impacto (numeros da base atual/demo)")
@SecurityRequirement(name = "bearerAuth")
public class MetricasController {

    private final MetricasImpactoService metricasImpactoService;

    public MetricasController(MetricasImpactoService metricasImpactoService) {
        this.metricasImpactoService = metricasImpactoService;
    }

    @GetMapping("/metricas/impacto")
    public MetricasImpactoResponse impacto() {
        return metricasImpactoService.calcular();
    }
}
