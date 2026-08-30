package com.smarthas.backend.controller;

import com.smarthas.backend.dto.ResumoIdosoResponse;
import com.smarthas.backend.dto.VincularCuidadorRequest;
import com.smarthas.backend.dto.VinculoCuidadorResponse;
import com.smarthas.backend.service.CuidadorService;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/cuidador")
@Tag(name = "Cuidador", description = "Modo cuidador: vinculo somente-leitura com um idoso/tutelado")
@SecurityRequirement(name = "bearerAuth")
public class CuidadorController {

    private final CuidadorService cuidadorService;

    public CuidadorController(CuidadorService cuidadorService) {
        this.cuidadorService = cuidadorService;
    }

    @PostMapping("/vincular")
    public ResponseEntity<Void> vincular(Authentication authentication, @Valid @RequestBody VincularCuidadorRequest request) {
        cuidadorService.vincular(authentication.getName(), request);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @GetMapping("/vinculos")
    public List<VinculoCuidadorResponse> vinculos(Authentication authentication) {
        return cuidadorService.listarVinculos(authentication.getName());
    }

    @GetMapping("/{idosoId}/resumo")
    public ResumoIdosoResponse resumo(Authentication authentication, @PathVariable String idosoId) {
        return cuidadorService.resumoDoIdoso(authentication.getName(), idosoId);
    }
}
