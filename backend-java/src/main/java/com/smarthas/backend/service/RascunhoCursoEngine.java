package com.smarthas.backend.service;

import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Gera uma estrutura inicial de modulos por TEMPLATE (regra fixa por nivel) -
 * nao e IA generativa, e um rascunho pra o tutor revisar e editar antes de
 * publicar. Espelha heuristics.py::gerar_rascunho_curso.
 */
@Component
public class RascunhoCursoEngine {

    private static final Map<String, List<String>> EXTRAS_POR_NIVEL = Map.of(
            "INTERMEDIARIO", List.of("Aprofundando: casos do dia a dia"),
            "AVANCADO", List.of("Aprofundando: casos do dia a dia", "Cenários avançados e exceções")
    );

    public List<String> gerar(String titulo, String nivel) {
        String tituloNormalizado = (titulo == null || titulo.isBlank()) ? "este assunto" : titulo.trim();

        List<String> modulos = new ArrayList<>(List.of(
                "Introdução: por que aprender " + tituloNormalizado,
                "Passo a passo com exemplos práticos",
                "Erros comuns e como evitá-los"
        ));
        modulos.addAll(EXTRAS_POR_NIVEL.getOrDefault(nivel == null ? "" : nivel.toUpperCase(), List.of()));
        modulos.add("Prática guiada e revisão final");
        return modulos;
    }
}
