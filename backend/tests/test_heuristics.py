from datetime import datetime, timedelta, timezone

from app.heuristics import (
    calcular_risco,
    calcular_sequencia_dias,
    detectar_tendencias,
    gerar_rascunho_curso,
    recomendar,
    responder_assistente,
)


def test_calcular_risco_pedido_no_prazo_e_baixo():
    pedido = {
        "id": 1, "historicoAtrasos": 0, "reagendamentos": 0,
        "estoqueDisponivel": True, "distanciaKm": 8, "statusAtual": "EM_TRANSITO",
    }
    resultado = calcular_risco(pedido)
    assert resultado["riscoNivel"] == "BAIXO"
    assert resultado["riscoScore"] == 0
    assert resultado["pedidoId"] == 1


def test_calcular_risco_pedido_atrasado_e_critico():
    pedido = {
        "id": 2, "historicoAtrasos": 3, "reagendamentos": 2,
        "estoqueDisponivel": False, "distanciaKm": 22, "statusAtual": "ATRASADO",
    }
    resultado = calcular_risco(pedido)
    # 3*18 + 2*12 + 25 + 15 + 20 = 54+24+25+15+20 = 138 -> clamp 100
    assert resultado["riscoScore"] == 100
    assert resultado["riscoNivel"] == "CRITICO"
    assert "reagendamento" in resultado["recomendacao"].lower()


def test_calcular_risco_impacto_clima_soma_ao_score():
    pedido = {
        "id": 5, "historicoAtrasos": 0, "reagendamentos": 0,
        "estoqueDisponivel": True, "distanciaKm": 8, "statusAtual": "EM_TRANSITO",
    }
    resultado = calcular_risco(pedido, impacto_clima=20)
    assert resultado["riscoScore"] == 20


def test_calcular_risco_impacto_clima_e_limitado_a_25():
    pedido = {
        "id": 6, "historicoAtrasos": 0, "reagendamentos": 0,
        "estoqueDisponivel": True, "distanciaKm": 8, "statusAtual": "EM_TRANSITO",
    }
    resultado = calcular_risco(pedido, impacto_clima=999)
    assert resultado["riscoScore"] == 25


def test_calcular_risco_score_nunca_passa_de_100():
    pedido = {
        "id": 9, "historicoAtrasos": 10, "reagendamentos": 10,
        "estoqueDisponivel": False, "distanciaKm": 50, "statusAtual": "ATRASADO",
    }
    resultado = calcular_risco(pedido)
    assert resultado["riscoScore"] == 100


_PEDIDO_ATRASADO = {
    "id": 2, "historicoAtrasos": 3, "reagendamentos": 2, "estoqueDisponivel": False,
    "distanciaKm": 22, "statusAtual": "ATRASADO", "prazoPrometido": "15/06/2026",
}
_PEDIDO_EM_DIA = {
    "id": 1, "historicoAtrasos": 0, "reagendamentos": 0, "estoqueDisponivel": True,
    "distanciaKm": 8, "statusAtual": "EM_TRANSITO", "prazoPrometido": "16/06/2026",
}


def test_assistente_usa_risco_real_do_pedido_atrasado():
    resposta = responder_assistente(pedido=_PEDIDO_ATRASADO, pergunta="Minha entrega pode atrasar?")
    assert resposta["acaoRecomendada"] == "REAGENDAR"
    assert "risco" in resposta["resposta"].lower()


def test_assistente_pedido_sem_risco_nao_recomenda_reagendar():
    resposta = responder_assistente(pedido=_PEDIDO_EM_DIA, pergunta="Minha entrega vai atrasar?")
    assert resposta["acaoRecomendada"] == "AGUARDAR"


def test_assistente_pergunta_de_prazo_retorna_prazo_do_pedido():
    resposta = responder_assistente(pedido=_PEDIDO_ATRASADO, pergunta="Quando chega meu pedido?")
    assert "15/06/2026" in resposta["resposta"]


def test_assistente_sem_pedido_responde_generico():
    resposta = responder_assistente(pedido=None, pergunta="Oi, tudo bem?")
    assert resposta["acaoRecomendada"] == "INFORMAR"


def test_recomendar_cold_start_prioriza_nivel_basico():
    resultado = recomendar("usuario-novo", eventos=[])
    assert resultado[0]["tipo"] == "curso"
    assert resultado[0].get("nivel") == "BASICO"


def test_recomendar_com_historico_da_bonus_de_novidade():
    agora = datetime.now(timezone.utc)
    eventos = [
        {"userId": "u1", "tipo": "curso", "referenceId": 1, "timestamp": agora - timedelta(days=1)},
        {"userId": "u1", "tipo": "curso", "referenceId": 1, "timestamp": agora - timedelta(days=1)},
    ]
    resultado = recomendar("u1", eventos)
    # curso 1 foi visitado ha 1 dia (sem bonus de novidade); outros itens
    # nunca visitados devem pontuar por novidade/descoberta e aparecer no topo.
    top_ids = [(r["tipo"], r["id"]) for r in resultado]
    assert ("curso", 1) not in top_ids[:1]


def test_detectar_tendencias_sinaliza_pico_de_categoria():
    agora = datetime.now(timezone.utc)
    eventos = []
    # Baixo volume historico (1 evento por dia, dias 10-20 atras).
    for dias_atras in range(10, 20):
        eventos.append({
            "userId": "u1", "tipo": "servico", "referenceId": 1,
            "categoria": "Previdencia", "timestamp": agora - timedelta(days=dias_atras),
        })
    # Pico nos ultimos 2 dias (muitos eventos = simula sazonalidade, ex: IR).
    for _ in range(8):
        eventos.append({
            "userId": "u2", "tipo": "servico", "referenceId": 1,
            "categoria": "Previdencia", "timestamp": agora - timedelta(days=1),
        })
    tendencias = detectar_tendencias(eventos)
    previdencia = next(t for t in tendencias if t["categoria"] == "Previdencia")
    assert previdencia["emAlta"] is True


def test_detectar_tendencias_sem_pico_nao_sinaliza():
    agora = datetime.now(timezone.utc)
    eventos = [
        {"userId": "u1", "tipo": "servico", "referenceId": 2, "categoria": "Saude",
         "timestamp": agora - timedelta(days=d)}
        for d in range(1, 10)
    ]
    tendencias = detectar_tendencias(eventos)
    saude = next(t for t in tendencias if t["categoria"] == "Saude")
    assert saude["emAlta"] is False


def test_gerar_rascunho_curso_basico_tem_estrutura_minima():
    modulos = gerar_rascunho_curso("Pix", "BASICO")
    assert len(modulos) == 4
    assert "Pix" in modulos[0]
    assert modulos[-1] == "Prática guiada e revisão final"


def test_gerar_rascunho_curso_avancado_tem_mais_modulos_que_basico():
    basico = gerar_rascunho_curso("Segurança digital", "BASICO")
    avancado = gerar_rascunho_curso("Segurança digital", "AVANCADO")
    assert len(avancado) > len(basico)


def test_gerar_rascunho_curso_titulo_vazio_usa_texto_generico():
    modulos = gerar_rascunho_curso("   ", "BASICO")
    assert "este assunto" in modulos[0]


def test_calcular_sequencia_dias_sem_eventos_e_zero():
    assert calcular_sequencia_dias([]) == 0


def test_calcular_sequencia_dias_evento_hoje_conta_um():
    agora = datetime.now(timezone.utc)
    assert calcular_sequencia_dias([agora]) == 1


def test_calcular_sequencia_dias_tres_dias_consecutivos():
    agora = datetime.now(timezone.utc)
    timestamps = [agora, agora - timedelta(days=1), agora - timedelta(days=2)]
    assert calcular_sequencia_dias(timestamps) == 3


def test_calcular_sequencia_dias_sem_uso_hoje_nem_ontem_quebra_a_sequencia():
    agora = datetime.now(timezone.utc)
    timestamps = [agora - timedelta(days=3), agora - timedelta(days=4)]
    assert calcular_sequencia_dias(timestamps) == 0


def test_calcular_sequencia_dias_gap_no_meio_conta_so_o_trecho_recente():
    agora = datetime.now(timezone.utc)
    timestamps = [agora, agora - timedelta(days=1), agora - timedelta(days=5)]
    assert calcular_sequencia_dias(timestamps) == 2
