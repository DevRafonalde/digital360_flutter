def test_pedidos_sem_token_retorna_401(client):
    resp = client.get("/pedidos")
    assert resp.status_code == 401


def test_listar_pedidos(client, auth_headers):
    resp = client.get("/pedidos", headers=auth_headers)
    assert resp.status_code == 200
    assert len(resp.json()) == 4


def test_detalhe_entrega_pedido_existente(client, auth_headers):
    resp = client.get("/pedidos/2/entrega", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["codigoPedido"] == "LM-2026-0002"


def test_detalhe_entrega_pedido_inexistente_404(client, auth_headers):
    resp = client.get("/pedidos/999/entrega", headers=auth_headers)
    assert resp.status_code == 404


def test_recalcular_risco_pedido_atrasado(client, auth_headers):
    resp = client.post("/entregas/2/recalcular-risco", headers=auth_headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["riscoNivel"] in ("ALTO", "CRITICO")
    assert body["pedidoId"] == 2


def test_assistente_logistico_pergunta(client, auth_headers):
    resp = client.post(
        "/assistente-logistico/pergunta",
        headers=auth_headers,
        json={"pedidoId": 2, "pergunta": "Minha entrega pode atrasar?"},
    )
    assert resp.status_code == 200
    assert resp.json()["acaoRecomendada"] == "REAGENDAR"


def test_feedback_entrega_nota_valida(client, auth_headers):
    resp = client.post(
        "/feedback-entrega", headers=auth_headers,
        json={"pedidoId": 1, "nota": 5, "comentario": "Chegou antes do prazo!"},
    )
    assert resp.status_code == 201


def test_feedback_entrega_nota_invalida_422(client, auth_headers):
    resp = client.post(
        "/feedback-entrega", headers=auth_headers,
        json={"pedidoId": 1, "nota": 9},
    )
    assert resp.status_code == 422


def test_feedback_entrega_pedido_inexistente_404(client, auth_headers):
    resp = client.post(
        "/feedback-entrega", headers=auth_headers,
        json={"pedidoId": 999, "nota": 5},
    )
    assert resp.status_code == 404


def test_registrar_evento_e_recomendacoes(client, auth_headers):
    # "userId" nao e mais enviado pelo cliente - a identidade vem do token.
    resp = client.post(
        "/eventos", headers=auth_headers,
        json={"tipo": "curso", "referenceId": 2, "categoria": "geral"},
    )
    assert resp.status_code == 201

    resp2 = client.get("/recomendacoes/usuario_teste", headers=auth_headers)
    assert resp2.status_code == 200
    assert len(resp2.json()) == 3


def test_recomendacoes_de_outro_usuario_retorna_403(client, auth_headers):
    resp = client.get("/recomendacoes/outra-pessoa", headers=auth_headers)
    assert resp.status_code == 403


def test_tendencias_endpoint_disponivel(client, auth_headers):
    resp = client.get("/tendencias", headers=auth_headers)
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)


def test_recalcular_risco_com_impacto_do_clima_aumenta_score(client, auth_headers):
    sem_clima = client.post("/entregas/1/recalcular-risco", headers=auth_headers, json={"impactoClima": 0})
    com_clima = client.post("/entregas/1/recalcular-risco", headers=auth_headers, json={"impactoClima": 20})
    assert com_clima.json()["riscoScore"] == sem_clima.json()["riscoScore"] + 20


def test_recalcular_risco_sem_body_usa_impacto_zero(client, auth_headers):
    resp = client.post("/entregas/1/recalcular-risco", headers=auth_headers)
    assert resp.status_code == 200


def test_reagendar_entrega_incrementa_contador_e_volta_pendente(client, auth_headers):
    resp = client.post("/pedidos/3/reagendar", headers=auth_headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["reagendamentos"] == 1
    assert body["statusAtual"] == "PENDENTE"


def test_reagendar_entrega_pedido_inexistente_404(client, auth_headers):
    resp = client.post("/pedidos/999/reagendar", headers=auth_headers)
    assert resp.status_code == 404


def test_listar_cursos_retorna_oficiais(client, auth_headers):
    resp = client.get("/cursos", headers=auth_headers)
    assert resp.status_code == 200
    assert len(resp.json()) == 4
    assert all(c["origem"] == "OFICIAL" for c in resp.json())


# ---------------------------------------------------------------------------
# Autenticacao real: registro, login, refresh
# ---------------------------------------------------------------------------
def test_registrar_usuario_com_sucesso(client):
    resp = client.post(
        "/auth/usuarios/registrar",
        json={"nomeUser": "novo_usuario", "senhaUser": "senha123", "aceitouPolitica": True},
    )
    assert resp.status_code == 201


def test_registrar_sem_aceitar_politica_retorna_422(client):
    resp = client.post(
        "/auth/usuarios/registrar",
        json={"nomeUser": "outro_usuario", "senhaUser": "senha123", "aceitouPolitica": False},
    )
    assert resp.status_code == 422


def test_registrar_usuario_duplicado_retorna_409(client):
    dados = {"nomeUser": "duplicado", "senhaUser": "senha123", "aceitouPolitica": True}
    client.post("/auth/usuarios/registrar", json=dados)
    resp = client.post("/auth/usuarios/registrar", json=dados)
    assert resp.status_code == 409


def test_login_com_sucesso_retorna_tokens(client):
    client.post(
        "/auth/usuarios/registrar",
        json={"nomeUser": "login_ok", "senhaUser": "senha123", "aceitouPolitica": True},
    )
    resp = client.post("/auth/usuarios/login", json={"nomeUser": "login_ok", "senhaUser": "senha123"})
    assert resp.status_code == 200
    body = resp.json()
    assert body["accessToken"]
    assert body["refreshToken"]
    assert body["nomeUser"] == "login_ok"


def test_login_com_senha_errada_retorna_401(client):
    client.post(
        "/auth/usuarios/registrar",
        json={"nomeUser": "login_errado", "senhaUser": "senha123", "aceitouPolitica": True},
    )
    resp = client.post("/auth/usuarios/login", json={"nomeUser": "login_errado", "senhaUser": "errada"})
    assert resp.status_code == 401


def test_refresh_token_valido_retorna_novos_tokens(client):
    client.post(
        "/auth/usuarios/registrar",
        json={"nomeUser": "refresh_ok", "senhaUser": "senha123", "aceitouPolitica": True},
    )
    login = client.post("/auth/usuarios/login", json={"nomeUser": "refresh_ok", "senhaUser": "senha123"})
    refresh_token = login.json()["refreshToken"]

    resp = client.post("/auth/refresh", json={"refreshToken": refresh_token})
    assert resp.status_code == 200
    body = resp.json()
    assert body["accessToken"]
    assert body["refreshToken"]


def test_refresh_token_invalido_retorna_401(client):
    resp = client.post("/auth/refresh", json={"refreshToken": "isso-nao-e-um-jwt"})
    assert resp.status_code == 401


def test_pedidos_com_token_malformado_retorna_401(client):
    resp = client.get("/pedidos", headers={"Authorization": "Bearer token-invalido"})
    assert resp.status_code == 401


# ---------------------------------------------------------------------------
# Cursos comunitarios: tutor, rascunho heuristico, criacao, "meus cursos"
# ---------------------------------------------------------------------------
def test_gerar_rascunho_sem_ser_tutor_retorna_403(client, auth_headers):
    resp = client.post(
        "/cursos/gerar-rascunho", headers=auth_headers,
        json={"titulo": "Uso de aplicativos bancários", "nivel": "BASICO"},
    )
    assert resp.status_code == 403


def test_tornar_tutor_habilita_gerar_rascunho(client, auth_headers):
    resp = client.post("/perfil/tornar-tutor", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["isTutor"] is True

    resp2 = client.post(
        "/cursos/gerar-rascunho", headers=auth_headers,
        json={"titulo": "Uso de aplicativos bancários", "nivel": "AVANCADO"},
    )
    assert resp2.status_code == 200
    topicos = resp2.json()["topicosSugeridos"]
    assert len(topicos) >= 4
    assert "aplicativos bancários" in topicos[0]


def test_criar_curso_sem_ser_tutor_retorna_403(client, auth_headers):
    resp = client.post(
        "/cursos", headers=auth_headers,
        json={"titulo": "Curso qualquer", "nivel": "BASICO", "topicosModulos": ["A"]},
    )
    assert resp.status_code == 403


def test_criar_curso_como_tutor_publica_direto_e_aparece_no_catalogo(client, auth_headers):
    client.post("/perfil/tornar-tutor", headers=auth_headers)

    resp = client.post(
        "/cursos", headers=auth_headers,
        json={
            "titulo": "Como usar o WhatsApp com segurança",
            "descricao": "Curso comunitário",
            "nivel": "BASICO",
            "cargaHoraria": 3,
            "topicosModulos": ["Introdução", "Prática"],
        },
    )
    assert resp.status_code == 201
    criado = resp.json()
    assert criado["origem"] == "COMUNIDADE"
    assert criado["status"] == "PUBLICADO"
    assert criado["autorId"] == "usuario_teste"

    catalogo = client.get("/cursos", headers=auth_headers).json()
    assert any(c["titulo"] == "Como usar o WhatsApp com segurança" for c in catalogo)


def test_criar_curso_sem_titulo_retorna_422(client, auth_headers):
    client.post("/perfil/tornar-tutor", headers=auth_headers)
    resp = client.post("/cursos", headers=auth_headers, json={"titulo": "   "})
    assert resp.status_code == 422


def test_meus_cursos_lista_so_os_do_proprio_tutor(client, auth_headers):
    client.post("/perfil/tornar-tutor", headers=auth_headers)
    client.post("/cursos", headers=auth_headers, json={"titulo": "Curso do tutor", "topicosModulos": []})

    resp = client.get("/cursos/meus", headers=auth_headers)
    assert resp.status_code == 200
    titulos = [c["titulo"] for c in resp.json()]
    assert titulos == ["Curso do tutor"]


# ---------------------------------------------------------------------------
# Forum: perguntas e respostas
# ---------------------------------------------------------------------------
def test_criar_pergunta_e_listar(client, auth_headers):
    resp = client.post(
        "/forum/perguntas", headers=auth_headers,
        json={"titulo": "Como uso o Pix?", "corpo": "Alguém pode me explicar o passo a passo?"},
    )
    assert resp.status_code == 201
    criada = resp.json()
    assert criada["titulo"] == "Como uso o Pix?"
    assert criada["totalRespostas"] == 0

    lista = client.get("/forum/perguntas", headers=auth_headers)
    assert lista.status_code == 200
    assert any(p["titulo"] == "Como uso o Pix?" for p in lista.json())


def test_criar_pergunta_vazia_retorna_422(client, auth_headers):
    resp = client.post("/forum/perguntas", headers=auth_headers, json={"titulo": "", "corpo": ""})
    assert resp.status_code == 422


def test_responder_pergunta_aparece_no_detalhe(client, auth_headers):
    pergunta = client.post(
        "/forum/perguntas", headers=auth_headers,
        json={"titulo": "Dúvida", "corpo": "Corpo da dúvida"},
    ).json()

    resp = client.post(
        f"/forum/perguntas/{pergunta['id']}/respostas", headers=auth_headers,
        json={"corpo": "Aqui está a resposta"},
    )
    assert resp.status_code == 201

    detalhe = client.get(f"/forum/perguntas/{pergunta['id']}", headers=auth_headers)
    assert detalhe.status_code == 200
    assert detalhe.json()["totalRespostas"] == 1
    assert detalhe.json()["respostas"][0]["corpo"] == "Aqui está a resposta"


def test_responder_pergunta_inexistente_404(client, auth_headers):
    resp = client.post(
        "/forum/perguntas/999/respostas", headers=auth_headers, json={"corpo": "Resposta"}
    )
    assert resp.status_code == 404


def test_detalhe_pergunta_inexistente_404(client, auth_headers):
    resp = client.get("/forum/perguntas/999", headers=auth_headers)
    assert resp.status_code == 404


# ---------------------------------------------------------------------------
# Gamificacao e metricas de impacto
# ---------------------------------------------------------------------------
def test_resumo_gamificacao_sem_eventos_e_zero(client, auth_headers):
    resp = client.get("/gamificacao/usuario_teste/resumo", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json() == {"cursosConcluidos": 0, "sequenciaDias": 0, "pontos": 0}


def test_resumo_gamificacao_de_outro_usuario_retorna_403(client, auth_headers):
    resp = client.get("/gamificacao/outra-pessoa/resumo", headers=auth_headers)
    assert resp.status_code == 403


def test_resumo_gamificacao_conta_curso_concluido(client, auth_headers):
    client.post(
        "/eventos", headers=auth_headers,
        json={"tipo": "curso_concluido", "referenceId": 1, "categoria": None},
    )
    resp = client.get("/gamificacao/usuario_teste/resumo", headers=auth_headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["cursosConcluidos"] == 1
    assert body["sequenciaDias"] == 1
    assert body["pontos"] == 110


def test_ranking_gamificacao_inclui_usuario_com_pontos(client, auth_headers):
    client.post(
        "/eventos", headers=auth_headers,
        json={"tipo": "curso_concluido", "referenceId": 1, "categoria": None},
    )
    resp = client.get("/gamificacao/ranking", headers=auth_headers)
    assert resp.status_code == 200
    nomes = [r["nomeAmigavel"] for r in resp.json()]
    assert "Usuário Teste" in nomes


def test_metricas_impacto_retorna_contadores_e_observacao(client, auth_headers):
    resp = client.get("/metricas/impacto", headers=auth_headers)
    assert resp.status_code == 200
    body = resp.json()
    assert "totalUsuarios" in body
    assert "totalCursosPublicados" in body
    assert "observacao" in body


def _registrar_e_logar(client, nome_user, **extra):
    client.post(
        "/auth/usuarios/registrar",
        json={
            "nomeUser": nome_user, "senhaUser": "senha-teste-123",
            "nomeAmigavel": nome_user.title(), "aceitouPolitica": True, **extra,
        },
    )
    resp = client.post("/auth/usuarios/login", json={"nomeUser": nome_user, "senhaUser": "senha-teste-123"})
    token = resp.json()["accessToken"]
    return {"Authorization": f"Bearer {token}"}


# ---------------------------------------------------------------------------
# Modo cuidador (somente leitura, vinculo direto por codigo)
# ---------------------------------------------------------------------------
def test_vincular_cuidador_com_sucesso(client, auth_headers):
    cuidador_headers = _registrar_e_logar(client, "cuidador_a")
    resp = client.post(
        "/cuidador/vincular", headers=cuidador_headers, json={"codigoIdoso": "usuario_teste"}
    )
    assert resp.status_code == 201
    assert resp.json()["idosoNome"] == "Usuário Teste"


def test_vincular_cuidador_a_si_mesmo_retorna_422(client, auth_headers):
    resp = client.post(
        "/cuidador/vincular", headers=auth_headers, json={"codigoIdoso": "usuario_teste"}
    )
    assert resp.status_code == 422


def test_vincular_cuidador_codigo_inexistente_retorna_404(client, auth_headers):
    cuidador_headers = _registrar_e_logar(client, "cuidador_b")
    resp = client.post(
        "/cuidador/vincular", headers=cuidador_headers, json={"codigoIdoso": "nao-existe"}
    )
    assert resp.status_code == 404


def test_vincular_cuidador_duplicado_retorna_409(client, auth_headers):
    cuidador_headers = _registrar_e_logar(client, "cuidador_c")
    client.post("/cuidador/vincular", headers=cuidador_headers, json={"codigoIdoso": "usuario_teste"})
    resp = client.post(
        "/cuidador/vincular", headers=cuidador_headers, json={"codigoIdoso": "usuario_teste"}
    )
    assert resp.status_code == 409


def test_listar_vinculos_cuidador(client, auth_headers):
    cuidador_headers = _registrar_e_logar(client, "cuidador_d")
    client.post("/cuidador/vincular", headers=cuidador_headers, json={"codigoIdoso": "usuario_teste"})
    resp = client.get("/cuidador/vinculos", headers=cuidador_headers)
    assert resp.status_code == 200
    assert any(v["idosoId"] == "usuario_teste" for v in resp.json())


def test_resumo_idoso_sem_vinculo_retorna_403(client, auth_headers):
    cuidador_headers = _registrar_e_logar(client, "cuidador_e")
    resp = client.get("/cuidador/usuario_teste/resumo", headers=cuidador_headers)
    assert resp.status_code == 403


def test_resumo_idoso_com_vinculo_retorna_dados(client, auth_headers):
    cuidador_headers = _registrar_e_logar(client, "cuidador_f")
    client.post("/cuidador/vincular", headers=cuidador_headers, json={"codigoIdoso": "usuario_teste"})
    resp = client.get("/cuidador/usuario_teste/resumo", headers=cuidador_headers)
    assert resp.status_code == 200
    assert resp.json()["idosoNome"] == "Usuário Teste"
    assert "cursosConcluidos" in resp.json()


# ---------------------------------------------------------------------------
# Indicacao
# ---------------------------------------------------------------------------
def test_registrar_com_codigo_indicacao_incrementa_contador(client, auth_headers):
    client.post(
        "/auth/usuarios/registrar",
        json={
            "nomeUser": "indicado_a", "senhaUser": "senha123",
            "aceitouPolitica": True, "codigoIndicacao": "usuario_teste",
        },
    )
    resp = client.get("/indicacoes/minhas", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json() == {"codigo": "usuario_teste", "totalIndicacoes": 1}


def test_registrar_com_codigo_indicacao_inexistente_nao_quebra(client):
    resp = client.post(
        "/auth/usuarios/registrar",
        json={
            "nomeUser": "indicado_b", "senhaUser": "senha123",
            "aceitouPolitica": True, "codigoIndicacao": "ninguem-com-esse-nome",
        },
    )
    assert resp.status_code == 201


def test_minhas_indicacoes_comeca_zerado(client, auth_headers):
    resp = client.get("/indicacoes/minhas", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json() == {"codigo": "usuario_teste", "totalIndicacoes": 0}


# ---------------------------------------------------------------------------
# Marketplace de tutores
# ---------------------------------------------------------------------------
def test_avaliar_curso_com_sucesso(client, auth_headers):
    resp = client.post(
        "/cursos/1/avaliar", headers=auth_headers, json={"nota": 5, "comentario": "Muito bom!"}
    )
    assert resp.status_code == 201
    assert resp.json()["nota"] == 5


def test_avaliar_curso_nota_invalida_422(client, auth_headers):
    resp = client.post("/cursos/1/avaliar", headers=auth_headers, json={"nota": 9})
    assert resp.status_code == 422


def test_avaliar_curso_inexistente_404(client, auth_headers):
    resp = client.post("/cursos/999/avaliar", headers=auth_headers, json={"nota": 5})
    assert resp.status_code == 404


def test_listar_avaliacoes_curso(client, auth_headers):
    client.post("/cursos/1/avaliar", headers=auth_headers, json={"nota": 4})
    resp = client.get("/cursos/1/avaliacoes", headers=auth_headers)
    assert resp.status_code == 200
    assert len(resp.json()) == 1


def test_perfil_tutor_inexistente_404(client, auth_headers):
    resp = client.get("/tutores/ninguem", headers=auth_headers)
    assert resp.status_code == 404


def test_excluir_conta_apaga_rascunho_e_orfaniza_curso_publicado(client, auth_headers):
    client.post("/perfil/tornar-tutor", headers=auth_headers)
    client.post(
        "/cursos", headers=auth_headers,
        json={"titulo": "Curso publicado do tutor", "topicosModulos": ["A"]},
    )
    curso_publicado_id = client.get("/cursos/meus", headers=auth_headers).json()[0]["id"]

    resp = client.delete("/perfil/conta", headers=auth_headers)
    assert resp.status_code == 200

    # Login com a conta excluida nao funciona mais.
    login = client.post(
        "/auth/usuarios/login", json={"nomeUser": "usuario_teste", "senhaUser": "senha-teste-123"}
    )
    assert login.status_code == 401

    # O curso publicado continua existindo (orfao), nao foi apagado.
    outro_headers = _registrar_e_logar(client, "outro_apos_exclusao")
    catalogo = client.get("/cursos", headers=outro_headers).json()
    curso_orfao = next(c for c in catalogo if c["id"] == curso_publicado_id)
    assert curso_orfao["autorId"] is None


def test_excluir_conta_remove_vinculos_de_cuidador(client, auth_headers):
    cuidador_headers = _registrar_e_logar(client, "cuidador_exclusao")
    client.post("/cuidador/vincular", headers=cuidador_headers, json={"codigoIdoso": "usuario_teste"})

    client.delete("/perfil/conta", headers=auth_headers)

    resp = client.get("/cuidador/vinculos", headers=cuidador_headers)
    assert resp.json() == []


def test_perfil_tutor_retorna_cursos_e_media(client, auth_headers):
    client.post("/perfil/tornar-tutor", headers=auth_headers)
    client.post(
        "/cursos", headers=auth_headers,
        json={"titulo": "Curso avaliado", "topicosModulos": ["A"]},
    )
    curso_id = client.get("/cursos/meus", headers=auth_headers).json()[0]["id"]
    client.post(f"/cursos/{curso_id}/avaliar", headers=auth_headers, json={"nota": 4})

    resp = client.get("/tutores/usuario_teste", headers=auth_headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["totalCursos"] == 1
    assert body["mediaAvaliacao"] == 4.0
    assert body["totalAvaliacoes"] == 1
