"""Motores heuristicos e de ML da AI Logistics Extension.

Risco, tendencias, assistente e gamificacao seguem deliberadamente baseados em
regras - decisao tomada na mentoria Leroy Merlin ("comece simples, escale com
consistencia"), adequada a decisoes que precisam ser auditaveis/explicaveis.

O motor de recomendacao (`recomendar`) evoluiu de heuristica pura para um
hibrido com filtragem colaborativa item-a-item real (similaridade de
cosseno sobre coocorrencia de uso entre usuarios) - ver docstring de
`recomendar` para os detalhes de quando cada sinal e usado. Continuamos sem
simular aprendizado onde nao ha dado: o sinal colaborativo so entra quando ha
eventos de mais de um usuario para comparar.
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


def _similaridade_cosseno(vetor_a: dict[str, float], vetor_b: dict[str, float]) -> float:
    """Cosseno entre dois vetores esparsos (dict usuario->peso). Pura Python,
    sem numpy/scikit-learn - mesma filosofia do resto do modulo: manter o MVP
    simples de instalar e auditar, sem trocar uma dependencia pesada por uma
    tecnica que da pra implementar em poucas linhas."""
    chaves_comuns = set(vetor_a) & set(vetor_b)
    if not chaves_comuns:
        return 0.0
    produto_escalar = sum(vetor_a[k] * vetor_b[k] for k in chaves_comuns)
    norma_a = sum(v * v for v in vetor_a.values()) ** 0.5
    norma_b = sum(v * v for v in vetor_b.values()) ** 0.5
    if norma_a == 0 or norma_b == 0:
        return 0.0
    return produto_escalar / (norma_a * norma_b)


def _similares_por_item(eventos: list[dict[str, Any]]) -> dict[tuple[str, int], dict[tuple[str, int], float]]:
    """Filtragem colaborativa item-a-item: para cada par de itens, calcula a
    similaridade de cosseno entre os vetores de interacao por usuario (quantas
    vezes cada usuario interagiu com cada item). Isso e ML de verdade (a
    tecnica classica de "quem viu X tambem viu Y"), nao uma regra fixa -
    mas so tem sinal real quando existem MULTIPLOS usuarios com itens em
    comum nos eventos; com um so usuario a matriz nao tem o que comparar e a
    funcao devolve vazio (ver `recomendar`, que ai cai 100% na heuristica de
    frequencia/novidade - nao ha ML fingido preenchendo a lacuna)."""
    vetores_por_item: dict[tuple[str, int], dict[str, float]] = {}
    for ev in eventos:
        chave_item = (ev["tipo"], ev["referenceId"])
        vetores_por_item.setdefault(chave_item, {})
        vetores_por_item[chave_item][ev["userId"]] = vetores_por_item[chave_item].get(ev["userId"], 0.0) + 1.0

    itens = list(vetores_por_item.keys())
    similares: dict[tuple[str, int], dict[tuple[str, int], float]] = {i: {} for i in itens}
    for idx_a, item_a in enumerate(itens):
        for item_b in itens[idx_a + 1:]:
            sim = _similaridade_cosseno(vetores_por_item[item_a], vetores_por_item[item_b])
            if sim > 0:
                similares[item_a][item_b] = sim
                similares[item_b][item_a] = sim
    return similares


def recomendar(user_id: str, eventos: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Combina duas fontes de sinal, nessa ordem de prioridade:

    1. Filtragem colaborativa item-a-item (ML real - similaridade de cosseno
       sobre coocorrencia de uso entre usuarios), quando ha dado de OUTROS
       usuarios que se sobreponha ao historico do usuario atual;
    2. Heuristica de frequencia + novidade (nao visitado ha mais de 14 dias)
       + leve prioridade a nivel BASICO em cold-start, sempre calculada como
       base e como fallback honesto quando (1) nao tem sinal - a maioria dos
       ambientes de demonstracao, ja que a base de eventos ainda e pequena.

    Isto documenta a evolucao descrita nos relatorios anteriores do grupo
    ("heuristica no MVP, ML real quando houver dado de uso suficiente") sem
    fingir aprendizado onde nao ha dado: o bonus colaborativo so aparece
    quando existe de fato coocorrencia entre usuarios nos eventos recebidos."""
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

    # Sinal colaborativo (ML): so calcula quando ha eventos de outros usuarios.
    outros_usuarios = {e["userId"] for e in eventos} - {user_id}
    similares = _similares_por_item(eventos) if outros_usuarios else {}

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

        score_colaborativo = 0.0
        if similares:
            # soma da similaridade com cada item que o usuario ja interagiu,
            # ponderada pela frequencia dele naquele item - quanto mais o
            # usuario usou um item, mais peso os "vizinhos" dele ganham.
            for chave_visitada, freq_visitada in frequencia.items():
                score_colaborativo += similares.get(chave_visitada, {}).get(chave, 0.0) * freq_visitada
        score += score_colaborativo * 15  # escala pro mesmo patamar da heuristica

        scored.append({
            **item,
            "score": round(score, 2),
            "diasDesdeUltimaVisita": dias_desde_visita,
            "origemScore": "colaborativo" if score_colaborativo > 0 else "heuristico",
        })

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
