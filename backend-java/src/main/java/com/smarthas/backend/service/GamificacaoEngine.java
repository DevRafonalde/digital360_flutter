package com.smarthas.backend.service;

import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Maior sequencia de dias consecutivos com pelo menos um evento de uso,
 * terminando hoje ou ontem. Espelha heuristics.py::calcular_sequencia_dias.
 */
@Component
public class GamificacaoEngine {

    public int calcularSequenciaDias(List<LocalDateTime> timestamps) {
        if (timestamps.isEmpty()) return 0;

        Set<LocalDate> dias = new HashSet<>();
        for (LocalDateTime t : timestamps) dias.add(t.toLocalDate());

        LocalDate hoje = LocalDate.now();
        LocalDate cursor;
        if (dias.contains(hoje)) {
            cursor = hoje;
        } else if (dias.contains(hoje.minusDays(1))) {
            cursor = hoje.minusDays(1);
        } else {
            return 0;
        }

        int sequencia = 0;
        while (dias.contains(cursor)) {
            sequencia++;
            cursor = cursor.minusDays(1);
        }
        return sequencia;
    }
}
