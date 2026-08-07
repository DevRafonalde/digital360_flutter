"""Motores heuristicos da AI Logistics Extension.

MVP deliberadamente baseado em regras (nao em ML) - decisao tomada na mentoria
Leroy Merlin ("comece simples, escale com consistencia"). A evolucao planejada
para modelos treinados com dados reais fica descrita no README, e nao e
simulada aqui com bibliotecas de ML que nao estariam de fato aprendendo nada.
"""
from __future__ import annotations

import statistics
from datetime import datetime, timedelta, timezone
from typing import Any

from .data import CATALOGO

NOVIDADE_DIAS = 14
JANELA_TENDENCIA_DIAS = 7
LIMIAR_DESVIOS = 1.5  # sensibilidade da deteccao de pico (em desvios-padrao)


def calcular_risco(pedido: dict[str, Any], impacto_clima: int = 0) -> dict[str, Any]:
    """Mesma heuristica de pontuacao usada no mock do app Flutter
    (mock_data.dart::calcularRisco), para o comportamento ser identico
    entre demo mockada e backend real. [impacto_clima] (0-25) vem do clima
    consultado via Open-Meteo pelo app - entra de verdade no score."""
    score = 0
    score += pedido["historicoAtrasos"] * 18
    score += pedido["reagendamentos"] * 12
    score += 0 if pedido["estoqueDisponivel"] else 25
    distancia = pedido["distanciaKm"]
    score += 15 if distancia > 20 else (8 if distancia > 10 else 0)
    if pedido["statusAtual"] == "ATRASADO":
        score += 20
    score += max(0, min(impacto_clima, 25))
    score = min(score, 100)

    if score >= 75:
        nivel, recomendacao = "CRITICO", "Acionar suporte logístico e oferecer reagendamento proativo."
    elif score >= 50:
        nivel, recomendacao = "ALTO", "Monitorar de perto e comunicar o cliente sobre possível atraso."
    elif score >= 25:
        nivel, recomendacao = "MEDIO", "Acompanhar a entrega no próximo ciclo de atualização."
    else:
        nivel, recomendacao = "BAIXO", "Entrega dentro do esperado. Nenhuma ação necessária."

    mensagem_cliente = (
        "Detectamos fatores que podem afetar a janela prometida."
        if score >= 50
        else "Sua entrega está dentro do prazo previsto."
    )

    return {
        "pedidoId": pedido["id"],
        "riscoScore": score,
        "riscoNivel": nivel,
        "recomendacao": recomendacao,
        "mensagemCliente": mensagem_cliente,
    }


def responder_assistente(pedido: dict[str, Any] | None, pergunta: str) -> dict[str, str]:
    """Diferente do fallback puramente textual do app (que so casa palavras-
    chave), aqui o assistente consulta o risco REAL do pedido antes de
    responder, quando um pedido e informado - a resposta reflete o estado
    atual da entrega, nao so o texto da pergunta. Recebe o dict do pedido ja
    resolvido pelo chamador (nao busca sozinho) - quem sabe onde os pedidos
    estao persistidos e o endpoint em main.py, nao este modulo."""
    q = pergunta.lower()
    risco = calcular_risco(pedido) if pedido else None

    if "atras" in q or "risco" in q:
        if risco and risco["riscoNivel"] in ("ALTO", "CRITICO"):
            return {
                "resposta": (
                    f"O pedido está com risco {risco['riscoNivel'].lower()} "
                    f"(score {risco['riscoScore']}/100). {risco['recomendacao']}"
                ),
                "acaoRecomendada": "REAGENDAR",
            }
        return {
            "resposta": "No momento não identificamos risco relevante de atraso para este pedido.",
            "acaoRecomendada": "AGUARDAR",
        }

    if "prazo" in q or "quando" in q:
        prazo = pedido["prazoPrometido"] if pedido else None
        if prazo:
            return {
                "resposta": f"O prazo prometido é {prazo}. Você será avisado se houver qualquer alteração.",
                "acaoRecomendada": "AGUARDAR",
            }
        return {
            "resposta": "O prazo prometido segue válido. Você receberá uma notificação caso haja alteração.",
            "acaoRecomendada": "AGUARDAR",
        }

    return {
        "resposta": "Estou acompanhando seu pedido em tempo real. Posso ajudar com prazo, status, risco de atraso ou reagendamento.",
        "acaoRecomendada": "INFORMAR",
    }


def recomendar(user_id: str, eventos: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Rankeia o catalogo por: frequencia de acesso recente (7 dias) do
    usuario + novidade (nao visitado ha mais de 14 dias) + leve prioridade
    para o nivel BASICO em cold-start (usuario sem historico).

    Espelha a descricao do motor heuristico dos documentos anteriores do
    projeto: "rankeamento por frequencia + nivel + recencia"."""
    agora = datetime.now(timezone.utc)
    eventos_usuario = [e for e in eventos if e["userId"] == user_id]

    if not eventos_usuario:
        # Cold start: prioriza o item de nivel mais basico e o primeiro servico.
        ordenado = sorted(
            CATALOGO,
            key=lambda it: (
                0 if it["tipo"] == "curso" and it.get("nivel") == "BASICO" else 1,
                it["tipo"],
                it["id"],
            ),
        )
        return [{**it, "score": 100 - i * 10, "motivo": "cold-start"} for i, it in enumerate(ordenado[:3])]

    ultima_visita: dict[tuple[str, int], datetime] = {}
    frequencia: dict[tuple[str, int], int] = {}
    for ev in eventos_usuario:
        chave = (ev["tipo"], ev["referenceId"])
        ts = ev["timestamp"]
        frequencia[chave] = frequencia.get(chave, 0) + 1
        if chave not in ultima_visita or ts > ultima_visita[chave]:
            ultima_visita[chave] = ts

    scored = []
    for item in CATALOGO:
        chave = (item["tipo"], item["id"])
        freq = frequencia.get(chave, 0)
        visitado_em = ultima_visita.get(chave)
        dias_desde_visita = (agora - visitado_em).days if visitado_em else 999

        score = freq * 5
        if dias_desde_visita > NOVIDADE_DIAS:
            score += 20  # bonus de novidade: nao visitado ha mais de 14 dias
        if visitado_em is None:
            score += 10  # nunca visitado - potencial de descoberta

        scored.append({**item, "score": score, "diasDesdeUltimaVisita": dias_desde_visita})

    scored.sort(key=lambda it: it["score"], reverse=True)
    return scored[:3]


def detectar_tendencias(eventos: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Deteccao de picos por categoria: compara o volume de eventos dos
    ultimos JANELA_TENDENCIA_DIAS dias contra a media historica diaria.
    Sinaliza "em_alta" quando o desvio e relevante - a mesma logica descrita
    nos documentos anteriores (media movel + limiar de desvio-padrao),
    implementada aqui em Python puro (sem pandas) para manter o MVP simples
    de instalar e auditar."""
    agora = datetime.now(timezone.utc)
    janela_inicio = agora - timedelta(days=JANELA_TENDENCIA_DIAS)

    por_categoria: dict[str, list[datetime]] = {}
    for ev in eventos:
        cat = ev.get("categoria", ev.get("tipo", "geral"))
        por_categoria.setdefault(cat, []).append(ev["timestamp"])

    tendencias = []
    for cat, timestamps in por_categoria.items():
        if len(timestamps) < 2:
            continue
        # Compara o volume da janela recente contra a media historica ANTERIOR
        # a ela (nao contaminada pelo proprio pico) - senao um pico inflaria
        # sua propria baseline e nunca seria detectado.
        recentes = [t for t in timestamps if t >= janela_inicio]
        historico = [t for t in timestamps if t < janela_inicio]
        volume_recente = len(recentes)

        if historico:
            contagens_diarias = _contagem_por_dia(historico, agora)
            media = statistics.mean(contagens_diarias)
            desvio = statistics.pstdev(contagens_diarias) if len(contagens_diarias) > 1 else 0
        else:
            media = desvio = 0

        limiar_janela = (media + LIMIAR_DESVIOS * desvio) * JANELA_TENDENCIA_DIAS
        em_alta = volume_recente > limiar_janela
        tendencias.append({
            "categoria": cat,
            "volumeUltimos7Dias": volume_recente,
            "mediaHistoricaDiaria": round(media, 2),
            "emAlta": em_alta,
        })
    return sorted(tendencias, key=lambda t: t["volumeUltimos7Dias"], reverse=True)


def gerar_rascunho_curso(titulo: str, nivel: str) -> list[str]:
    """Gera uma estrutura inicial de modulos por TEMPLATE (regra fixa por
    nivel) - nao e IA generativa, e um rascunho pra revisar e editar antes de
    publicar. Mesmo principio de honestidade do resto deste modulo: nao ha
    chave de LLM disponivel neste ambiente, entao nao simulamos uma."""
    titulo_normalizado = titulo.strip() or "este assunto"
    modulos = [
        f"Introdução: por que aprender {titulo_normalizado}",
        "Passo a passo com exemplos práticos",
        "Erros comuns e como evitá-los",
    ]
    extras_por_nivel = {
        "INTERMEDIARIO": ["Aprofundando: casos do dia a dia"],
        "AVANCADO": ["Aprofundando: casos do dia a dia", "Cenários avançados e exceções"],
    }
    modulos.extend(extras_por_nivel.get(nivel.upper(), []))
    modulos.append("Prática guiada e revisão final")
    return modulos


def calcular_sequencia_dias(timestamps: list[datetime]) -> int:
    """Maior sequencia de dias consecutivos com pelo menos um evento de uso,
    terminando hoje ou ontem (se o usuario nao usou o app hoje nem ontem, a
    sequencia "quebrou" e volta a zero) - gamificacao simples baseada em
    regra, no mesmo espirito do resto deste modulo."""
    if not timestamps:
        return 0
    dias = {t.date() for t in timestamps}
    hoje = datetime.now(timezone.utc).date()
    if hoje in dias:
        cursor = hoje
    elif (hoje - timedelta(days=1)) in dias:
        cursor = hoje - timedelta(days=1)
    else:
        return 0

    sequencia = 0
    while cursor in dias:
        sequencia += 1
        cursor -= timedelta(days=1)
    return sequencia


def _contagem_por_dia(timestamps: list[datetime], agora: datetime) -> list[int]:
    dias = {}
    for t in timestamps:
        chave = (agora - t).days
        dias[chave] = dias.get(chave, 0) + 1
    return list(dias.values())
