package com.smarthas.backend.service;

import com.smarthas.backend.dto.RespostaAssistente;
import org.springframework.stereotype.Service;

/**
 * Assistente conversacional simples baseado em regras (mesma logica do
 * MockData.respostaAssistente() do app). Isolado em service proprio para,
 * no futuro, ser substituido por uma chamada ao backend de IA em Python
 * sem alterar o controller.
 */
@Service
public class AssistenteService {

    public RespostaAssistente responder(String pergunta) {
        String q = pergunta.toLowerCase();

        if (q.contains("atras")) {
            return new RespostaAssistente(
                    "Identificamos risco elevado neste pedido. Recomendamos acionar o suporte "
                            + "logistico antes do prazo para um reagendamento proativo.",
                    "REAGENDAR");
        }
        if (q.contains("prazo") || q.contains("quando")) {
            return new RespostaAssistente(
                    "O prazo prometido segue valido. Voce recebera uma notificacao caso haja "
                            + "qualquer alteracao na janela de entrega.",
                    "AGUARDAR");
        }
        return new RespostaAssistente(
                "Estou acompanhando seu pedido em tempo real. Posso ajudar com prazo, status, "
                        + "risco de atraso ou reagendamento.",
                "INFORMAR");
    }
}
