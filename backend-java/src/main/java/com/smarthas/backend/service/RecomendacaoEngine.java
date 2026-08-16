package com.smarthas.backend.service;

import com.smarthas.backend.dto.ItemRecomendado;
import com.smarthas.backend.model.Evento;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Rankeia o catalogo por frequencia de acesso recente + novidade (nao
 * visitado ha mais de 14 dias) + leve prioridade ao nivel BASICO em
 * cold-start (usuario sem historico). Espelha heuristics.py::recomendar.
 */
@Component
public class RecomendacaoEngine {

    private static final int NOVIDADE_DIAS = 14;

    public List<ItemRecomendado> recomendar(String userId, List<Evento> todosEventos) {
        List<Evento> eventosUsuario = todosEventos.stream()
                .filter(e -> e.getUserId().equals(userId))
                .toList();

        if (eventosUsuario.isEmpty()) {
            return coldStart();
        }

        LocalDateTime agora = LocalDateTime.now();
        Map<String, Integer> frequencia = new HashMap<>();
        Map<String, LocalDateTime> ultimaVisita = new HashMap<>();

        for (Evento ev : eventosUsuario) {
            String chave = ev.getTipo() + ":" + ev.getReferenceId();
            frequencia.merge(chave, 1, Integer::sum);
            ultimaVisita.merge(chave, ev.getTimestamp(),
                    (atual, novo) -> novo.isAfter(atual) ? novo : atual);
        }

        List<ItemRecomendado> pontuados = new ArrayList<>();
        for (CatalogoItem item : Catalogo.ITENS) {
            String chave = item.tipo() + ":" + item.id();
            int freq = frequencia.getOrDefault(chave, 0);
            LocalDateTime visitadoEm = ultimaVisita.get(chave);
            long diasDesdeVisita = visitadoEm == null ? 999 : Duration.between(visitadoEm, agora).toDays();

            int score = freq * 5;
            if (diasDesdeVisita > NOVIDADE_DIAS) score += 20;
            if (visitadoEm == null) score += 10;

            pontuados.add(new ItemRecomendado(
                    item.tipo(), item.id(), item.titulo(), item.nivel(), item.categoria(),
                    score, null, (int) diasDesdeVisita
            ));
        }

        return pontuados.stream()
                .sorted(Comparator.comparingInt(ItemRecomendado::score).reversed())
                .limit(3)
                .toList();
    }

    private List<ItemRecomendado> coldStart() {
        List<CatalogoItem> ordenado = Catalogo.ITENS.stream()
                .sorted(Comparator
                        .<CatalogoItem>comparingInt(it -> ("curso".equals(it.tipo()) && "BASICO".equals(it.nivel())) ? 0 : 1)
                        .thenComparing(CatalogoItem::tipo)
                        .thenComparing(CatalogoItem::id))
                .limit(3)
                .toList();

        List<ItemRecomendado> resultado = new ArrayList<>();
        for (int i = 0; i < ordenado.size(); i++) {
            CatalogoItem item = ordenado.get(i);
            resultado.add(new ItemRecomendado(
                    item.tipo(), item.id(), item.titulo(), item.nivel(), item.categoria(),
                    100 - i * 10, "cold-start", null
            ));
        }
        return resultado;
    }
}
