package com.smarthas.backend.controller;

import com.smarthas.backend.dto.LoginResponse;
import com.smarthas.backend.dto.RefreshRequest;
import com.smarthas.backend.service.AuthService;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

/** Rota separada (fora de /auth/usuarios) para casar com ApiService.refresh() do app Flutter. */
@RestController
@Tag(name = "Autenticacao", description = "Renovacao de sessao (publico, sem Bearer)")
public class RefreshController {

    private final AuthService authService;

    public RefreshController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/auth/refresh")
    public LoginResponse refresh(@Valid @RequestBody RefreshRequest request) {
        return authService.refresh(request.refreshToken());
    }
}
