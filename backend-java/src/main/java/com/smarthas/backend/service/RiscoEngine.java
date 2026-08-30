package com.smarthas.backend.service;

import com.smarthas.backend.dto.RiscoLogisticoResponse;
import com.smarthas.backend.model.PedidoLogistico;
import org.springframework.stereotype.Component;

/**
 * Motor de risco de entrega (regras/heuristica), isolado do controller/service
 * de pedidos para manter uma unica responsabilidade por classe.
 * Mesma formula usada no MockData.calcularRisco() do app Flutter, para o
 * dashboard, o app e o backend mostrarem sempre o mesmo resultado.
 */
@Component
public class RiscoEngine {

    public RiscoLogisticoResponse calcular(PedidoLogistico pedido) {
        return calcular(pedido, 0);
    }

    /** impactoClima (0-25): quanto o clima real consultado pelo app soma ao score. */
    public RiscoLogisticoResponse calcular(PedidoLogistico pedido, int impactoClima) {
        int score = 0;
        score += pedido.getHistoricoAtrasos() * 18;
        score += pedido.getReagendamentos() * 12;
        score += pedido.getEstoqueDisponivel() ? 0 : 25;
        score += pedido.getDistanciaKm() > 20 ? 15 : (pedido.getDistanciaKm() > 10 ? 8 : 0);
        if ("ATRASADO".equals(pedido.getStatusAtual())) {
            score += 20;
        }
        score += Math.max(0, Math.min(impactoClima, 25));
        score = Math.min(score, 100);

        String nivel;
        String recomendacao;
        if (score >= 75) {
            nivel = "CRITICO";
            recomendacao = "Acionar suporte logistico e oferecer reagendamento proativo.";
        } else if (score >= 50) {
            nivel = "ALTO";
            recomendacao = "Monitorar de perto e comunicar o cliente sobre possivel atraso.";
        } else if (score >= 25) {
            nivel = "MEDIO";
            recomendacao = "Acompanhar a entrega no proximo ciclo de atualizacao.";
        } else {
            nivel = "BAIXO";
            recomendacao = "Entrega dentro do esperado. Nenhuma acao necessaria.";
        }

        String mensagemCliente = score >= 50
                ? "Detectamos fatores que podem afetar a janela prometida."
                : "Sua entrega esta dentro do prazo previsto.";

        return new RiscoLogisticoResponse(pedido.getId(), score, nivel, recomendacao, mensagemCliente);
    }
}
