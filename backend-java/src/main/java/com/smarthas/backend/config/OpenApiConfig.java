package com.smarthas.backend.config;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.info.Info;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import org.springframework.context.annotation.Configuration;

@Configuration
@OpenAPIDefinition(
        info = @Info(
                title = "Smart HAS / Digital 360 API",
                version = "1.0.0",
                description = "API REST do app Digital 360 (Smart HAS, Sociedade 5.0) - FIAP Fase 5. "
                        + "Fornece autenticacao, trilhas de curso, guia de servicos publicos e a "
                        + "camada AI Logistics Extension (pedidos, risco de entrega, assistente)."
        )
)
@SecurityScheme(
        name = "bearerAuth",
        type = SecuritySchemeType.HTTP,
        scheme = "bearer",
        bearerFormat = "JWT"
)
public class OpenApiConfig {
}
