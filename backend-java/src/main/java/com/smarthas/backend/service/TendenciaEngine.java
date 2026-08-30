package com.smarthas.backend.service;

import com.smarthas.backend.dto.TendenciaResponse;
import com.smarthas.backend.model.Evento;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.*;

/**
 * Deteccao de picos por categoria: compara o volume de eventos dos ultimos 7
 * dias contra a media historica diaria (janela anterior, para nao contaminar
 * a propria baseline com o pico). Espelha heuristics.py::detectar_tendencias.
 */
@Component
public class TendenciaEngine {

    private static final int JANELA_DIAS = 7;
    private static final double LIMIAR_DESVIOS = 1.5;

    public List<TendenciaResponse> detectar(List<Evento> eventos) {
        LocalDateTime agora = LocalDateTime.now();
        LocalDateTime janelaInicio = agora.minusDays(JANELA_DIAS);

        Map<String, List<LocalDateTime>> porCategoria = new LinkedHashMap<>();
        for (Evento ev : eventos) {
            String categoria = ev.getCategoria() != null ? ev.getCategoria() : ev.getTipo();
            porCategoria.computeIfAbsent(categoria, k -> new ArrayList<>()).add(ev.getTimestamp());
        }

        List<TendenciaResponse> tendencias = new ArrayList<>();
        for (var entry : porCategoria.entrySet()) {
            List<LocalDateTime> timestamps = entry.getValue();
            if (timestamps.size() < 2) continue;

            List<LocalDateTime> recentes = timestamps.stream().filter(t -> !t.isBefore(janelaInicio)).toList();
            List<LocalDateTime> historico = timestamps.stream().filter(t -> t.isBefore(janelaInicio)).toList();
            int volumeRecente = recentes.size();

            double media = 0;
            double desvio = 0;
            if (!historico.isEmpty()) {
                Map<Long, Integer> contagensPorDia = new HashMap<>();
                for (LocalDateTime t : historico) {
                    long diasAtras = Duration.between(t, agora).toDays();
                    contagensPorDia.merge(diasAtras, 1, Integer::sum);
                }
                List<Integer> contagens = new ArrayList<>(contagensPorDia.values());
                media = contagens.stream().mapToInt(Integer::intValue).average().orElse(0);
                if (contagens.size() > 1) {
                    final double mediaCalculada = media;
                    double variancia = contagens.stream()
                            .mapToDouble(c -> Math.pow(c - mediaCalculada, 2))
                            .average().orElse(0);
                    desvio = Math.sqrt(variancia);
                }
            }

            double limiarJanela = (media + LIMIAR_DESVIOS * desvio) * JANELA_DIAS;
            boolean emAlta = volumeRecente > limiarJanela;

            tendencias.add(new TendenciaResponse(entry.getKey(), volumeRecente,
                    Math.round(media * 100.0) / 100.0, emAlta));
        }

        return tendencias.stream()
                .sorted(Comparator.comparingInt(TendenciaResponse::volumeUltimos7Dias).reversed())
                .toList();
    }
}
