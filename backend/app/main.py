"""API da AI Logistics Extension - Smart HAS / Digital 360 (Enterprise Challenge Leroy Merlin).

Implementa o contrato descrito em CONTRATO_APIS_AI_LOGISTICS.md. A partir
desta versao, roda sobre SQLite (persistencia real) e autenticacao JWT real
(access + refresh, amarrados a identidade do usuario) - as duas limitacoes
que a versao anterior documentava conscientemente como MVP agora estao
resolvidas. O motor de recomendacao/risco continua heuristico (baseado em
regras) por decisao deliberada da mentoria Leroy Merlin ("comece simples,
escale com consistencia"), nao ML - ver heuristics.py.
"""
from __future__ import annotations

import os
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from typing import Any

from fastapi import Depends, FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sqlalchemy.orm import Session

from .auth import (
    UsuarioAutenticado,
    criar_access_token,
    criar_refresh_token,
    decodificar_token,
    hash_senha,
    usuario_atual,
    verificar_senha,
)
from .cors_config import allowed_origins
from .db import criar_tabelas, get_db, seed_if_empty
from .db_models import (
    AvaliacaoCursoORM,
    CursoORM,
    EventoORM,
    FeedbackORM,
    PedidoORM,
    PerguntaForumORM,
    RespostaForumORM,
    UsuarioORM,
    VinculoCuidadorORM,
)
from .heuristics import (
    calcular_risco,
    calcular_sequencia_dias,
    detectar_tendencias,
    gerar_rascunho_curso,
    recomendar,
    responder_assistente,
)


@asynccontextmanager
async def _lifespan(app: FastAPI):
    if os.environ.get("TESTING"):
        # Nos testes, o banco e as seeds sao controlados pelas fixtures em
        # conftest.py (transacao isolada por teste) - o startup real (banco
        # de arquivo em disco) nao deve rodar nesse caso.
        yield
        return
    criar_tabelas()
    db = next(get_db())
    try:
        seed_if_empty(db)
    finally:
        db.close()
    yield


app = FastAPI(
    title="Digital 360 - AI Logistics Extension API",
    description="Backend real (persistencia SQLite + autenticacao JWT + MVP heuristico) da camada AI Logistics Extension.",
    version="2.0.0",
    lifespan=_lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins(),
    allow_methods=["*"],
    allow_headers=["*"],
)


def _pedido_ou_404(db: Session, pedido_id: int) -> PedidoORM:
    pedido = db.query(PedidoORM).filter(PedidoORM.id == pedido_id).first()
    if pedido is None:
        raise HTTPException(status_code=404, detail="Pedido não encontrado")
    return pedido


def _eventos_como_dicts(db: Session) -> list[dict[str, Any]]:
    """Converte as linhas de EventoORM pro mesmo formato de dict que o motor
    heuristico (heuristics.py) ja espera - mantem esse modulo sem depender
    do ORM, so de estruturas simples."""
    def _com_utc(ts: datetime) -> datetime:
        # SQLite nao guarda timezone - o SQLAlchemy devolve datetime "naive"
        # ao ler de volta, mesmo tendo sido salvo como UTC. Sem isso, o
        # heuristics.py (que so trabalha com datetimes aware) quebra ao
        # subtrair um "aware" (agora) de um "naive" (do banco).
        return ts if ts.tzinfo is not None else ts.replace(tzinfo=timezone.utc)

    return [
        {
            "userId": e.user_id,
            "tipo": e.tipo,
            "referenceId": e.reference_id,
            "categoria": e.categoria,
            "timestamp": _com_utc(e.timestamp),
        }
        for e in db.query(EventoORM).all()
    ]


# ---------------------------------------------------------------------------
# Autenticacao real (registro, login, refresh)
# ---------------------------------------------------------------------------
class RegistrarBody(BaseModel):
    nomeUser: str
    senhaUser: str
    nomeAmigavel: str = ""
    nomeCompleto: str = ""
    cpf: str = ""
    aceitouPolitica: bool = False
    codigoIndicacao: str | None = None


@app.post("/auth/usuarios/registrar", status_code=201)
def registrar(body: RegistrarBody, db: Session = Depends(get_db)) -> dict[str, Any]:
    if not body.aceitouPolitica:
        raise HTTPException(status_code=422, detail="É necessário aceitar a política de privacidade")
    if not body.nomeUser.strip() or not body.senhaUser:
        raise HTTPException(status_code=422, detail="Usuário e senha são obrigatórios")
    if db.query(UsuarioORM).filter(UsuarioORM.nome_user == body.nomeUser).first() is not None:
        raise HTTPException(status_code=409, detail="Usuário já cadastrado")

    usuario = UsuarioORM(
        nome_user=body.nomeUser,
        senha_hash=hash_senha(body.senhaUser),
        nome_amigavel=body.nomeAmigavel or body.nomeUser,
        nome_completo=body.nomeCompleto,
        cpf=body.cpf,
        aceitou_politica_em=datetime.now(timezone.utc),
    )
    db.add(usuario)

    # Codigo de indicacao e o proprio nomeUser de quem indicou (ja unico) -
    # se corresponder a alguem real, credita a indicacao. Silencioso se o
    # codigo nao existir, pra nao vazar quais nomes de usuario sao validos.
    if body.codigoIndicacao and body.codigoIndicacao != body.nomeUser:
        indicador = db.query(UsuarioORM).filter(UsuarioORM.nome_user == body.codigoIndicacao).first()
        if indicador is not None:
            indicador.total_indicacoes += 1

    db.commit()
    return {"status": "registrado"}


class LoginBody(BaseModel):
    nomeUser: str
    senhaUser: str


@app.post("/auth/usuarios/login")
def login(body: LoginBody, db: Session = Depends(get_db)) -> dict[str, Any]:
    usuario = db.query(UsuarioORM).filter(UsuarioORM.nome_user == body.nomeUser).first()
    if usuario is None or not verificar_senha(body.senhaUser, usuario.senha_hash):
        raise HTTPException(status_code=401, detail="Usuário ou senha incorretos")

    return {
        "id": usuario.id,
        "nomeAmigavel": usuario.nome_amigavel,
        "nomeUser": usuario.nome_user,
        "accessToken": criar_access_token(usuario.id, usuario.nome_user),
        "refreshToken": criar_refresh_token(usuario.id, usuario.nome_user),
        "cpf": usuario.cpf,
        "nomeCompleto": usuario.nome_completo,
        "isTutor": usuario.is_tutor,
    }


class RefreshBody(BaseModel):
    refreshToken: str


@app.post("/auth/refresh")
def renovar_sessao(body: RefreshBody, db: Session = Depends(get_db)) -> dict[str, str]:
    payload = decodificar_token(body.refreshToken, "refresh")
    usuario = db.query(UsuarioORM).filter(UsuarioORM.id == payload["uid"]).first()
    if usuario is None:
        raise HTTPException(status_code=401, detail="Usuário não encontrado")
    return {
        "accessToken": criar_access_token(usuario.id, usuario.nome_user),
        "refreshToken": criar_refresh_token(usuario.id, usuario.nome_user),
    }


# ---------------------------------------------------------------------------
# GET /pedidos
# ---------------------------------------------------------------------------
@app.get("/pedidos")
def listar_pedidos(
    _: UsuarioAutenticado = Depends(usuario_atual), db: Session = Depends(get_db)
) -> list[dict[str, Any]]:
    return [p.as_dict() for p in db.query(PedidoORM).all()]


# ---------------------------------------------------------------------------
# GET /pedidos/{id}/entrega
# ---------------------------------------------------------------------------
@app.get("/pedidos/{pedido_id}/entrega")
def detalhe_entrega(
    pedido_id: int, _: UsuarioAutenticado = Depends(usuario_atual), db: Session = Depends(get_db)
) -> dict[str, Any]:
    return _pedido_ou_404(db, pedido_id).as_dict()


# ---------------------------------------------------------------------------
# POST /entregas/{id}/recalcular-risco
# ---------------------------------------------------------------------------
class RecalcularRiscoBody(BaseModel):
    impactoClima: int = 0


@app.post("/entregas/{pedido_id}/recalcular-risco")
def recalcular_risco(
    pedido_id: int,
    body: RecalcularRiscoBody | None = None,
    _: UsuarioAutenticado = Depends(usuario_atual),
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    pedido = _pedido_ou_404(db, pedido_id)
    impacto_clima = body.impactoClima if body else 0
    return calcular_risco(pedido.as_dict(), impacto_clima=impacto_clima)


# ---------------------------------------------------------------------------
# POST /pedidos/{id}/reagendar
# ---------------------------------------------------------------------------
@app.post("/pedidos/{pedido_id}/reagendar")
def reagendar_entrega(
    pedido_id: int, _: UsuarioAutenticado = Depends(usuario_atual), db: Session = Depends(get_db)
) -> dict[str, Any]:
    pedido = _pedido_ou_404(db, pedido_id)
    pedido.reagendamentos += 1
    pedido.status_atual = "PENDENTE"
    db.commit()
    return {"pedidoId": pedido_id, "reagendamentos": pedido.reagendamentos, "statusAtual": pedido.status_atual}


# ---------------------------------------------------------------------------
# POST /assistente-logistico/pergunta
# ---------------------------------------------------------------------------
class PerguntaAssistente(BaseModel):
    pedidoId: int | None = None
    pergunta: str


@app.post("/assistente-logistico/pergunta")
def assistente_logistico(
    body: PerguntaAssistente,
    _: UsuarioAutenticado = Depends(usuario_atual),
    db: Session = Depends(get_db),
) -> dict[str, str]:
    pedido = db.query(PedidoORM).filter(PedidoORM.id == body.pedidoId).first() if body.pedidoId else None
    return responder_assistente(pedido.as_dict() if pedido else None, body.pergunta)


# ---------------------------------------------------------------------------
# POST /feedback-entrega
# ---------------------------------------------------------------------------
class FeedbackEntrega(BaseModel):
    pedidoId: int
    nota: int
    comentario: str | None = None


@app.post("/feedback-entrega", status_code=201)
def feedback_entrega(
    body: FeedbackEntrega,
    _: UsuarioAutenticado = Depends(usuario_atual),
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    _pedido_ou_404(db, body.pedidoId)
    if not 1 <= body.nota <= 5:
        raise HTTPException(status_code=422, detail="nota deve estar entre 1 e 5")
    db.add(FeedbackORM(pedido_id=body.pedidoId, nota=body.nota, comentario=body.comentario))
    db.commit()
    total = db.query(FeedbackORM).count()
    return {"status": "registrado", "totalFeedbacks": total}


# ---------------------------------------------------------------------------
# POST /eventos  (alimenta o motor de recomendacao e a deteccao de picos)
# ---------------------------------------------------------------------------
class UserEvent(BaseModel):
    tipo: str  # "curso" | "servico" | "curso_concluido" (gamificacao)
    referenceId: int
    categoria: str | None = None


@app.post("/eventos", status_code=201)
def registrar_evento(
    body: UserEvent,
    usuario: UsuarioAutenticado = Depends(usuario_atual),
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    # A identidade vem do token (nao mais de um campo que o cliente informa
    # livremente) - fecha a lacuna de autorizacao que a versao anterior
    # documentava conscientemente.
    db.add(EventoORM(
        user_id=usuario.nome_user,
        tipo=body.tipo,
        reference_id=body.referenceId,
        categoria=body.categoria,
    ))
    db.commit()
    total = db.query(EventoORM).count()
    return {"status": "registrado", "totalEventos": total}


# ---------------------------------------------------------------------------
# GET /recomendacoes/{userId}
# ---------------------------------------------------------------------------
@app.get("/recomendacoes/{user_id}")
def recomendacoes(
    user_id: str,
    usuario: UsuarioAutenticado = Depends(usuario_atual),
    db: Session = Depends(get_db),
) -> list[dict[str, Any]]:
    if usuario.nome_user != user_id:
        raise HTTPException(status_code=403, detail="Você só pode consultar suas próprias recomendações")
    return recomendar(user_id, _eventos_como_dicts(db))


# ---------------------------------------------------------------------------
# GET /tendencias  (deteccao de picos/sazonalidade)
# ---------------------------------------------------------------------------
@app.get("/tendencias")
def tendencias(
    _: UsuarioAutenticado = Depends(usuario_atual), db: Session = Depends(get_db)
) -> list[dict[str, Any]]:
    return detectar_tendencias(_eventos_como_dicts(db))


# ---------------------------------------------------------------------------
# GET /cursos  (oficiais - autoria por tutores chega na Fase 3)
# ---------------------------------------------------------------------------
@app.get("/cursos")
def listar_cursos(
    _: UsuarioAutenticado = Depends(usuario_atual), db: Session = Depends(get_db)
) -> list[dict[str, Any]]:
    cursos = db.query(CursoORM).filter(CursoORM.status == "PUBLICADO").all()
    return [c.as_dict() for c in cursos]


def _exigir_tutor(usuario: UsuarioAutenticado) -> None:
    if not usuario.is_tutor:
        raise HTTPException(status_code=403, detail="Recurso disponível apenas para tutores")


# ---------------------------------------------------------------------------
# DELETE /perfil/conta  (LGPD - exclusao da propria conta)
# ---------------------------------------------------------------------------
@app.delete("/perfil/conta")
def excluir_conta(
    usuario: UsuarioAutenticado = Depends(usuario_atual), db: Session = Depends(get_db)
) -> dict[str, str]:
    # Rascunhos do proprio tutor sao apagados (nunca chegaram a existir pra
    # mais ninguem). Cursos ja PUBLICADOS ficam orfaos (autor_id=None) em vez
    # de apagados - apagar quebraria o catalogo de quem ja estuda por eles.
    db.query(CursoORM).filter(
        CursoORM.autor_id == usuario.id, CursoORM.status == "RASCUNHO"
    ).delete()
    db.query(CursoORM).filter(CursoORM.autor_id == usuario.id).update({"autor_id": None})
    db.query(VinculoCuidadorORM).filter(
        (VinculoCuidadorORM.cuidador_id == usuario.id) | (VinculoCuidadorORM.idoso_id == usuario.id)
    ).delete(synchronize_session=False)
    db.query(UsuarioORM).filter(UsuarioORM.id == usuario.id).delete()
    db.commit()
    return {"status": "conta excluída"}


# ---------------------------------------------------------------------------
# POST /perfil/tornar-tutor  (auto-atribuicao, sem fila de aprovacao)
# ---------------------------------------------------------------------------
@app.post("/perfil/tornar-tutor")
def tornar_tutor(
    usuario: UsuarioAutenticado = Depends(usuario_atual), db: Session = Depends(get_db)
) -> dict[str, bool]:
    usuario_orm = db.query(UsuarioORM).filter(UsuarioORM.id == usuario.id).first()
    usuario_orm.is_tutor = True
    db.commit()
    return {"isTutor": True}


# ---------------------------------------------------------------------------
# POST /cursos/gerar-rascunho  (heuristica por template - NAO IA generativa)
# ---------------------------------------------------------------------------
class GerarRascunhoBody(BaseModel):
    titulo: str
    nivel: str = "BASICO"


@app.post("/cursos/gerar-rascunho")
def gerar_rascunho(
    body: GerarRascunhoBody, usuario: UsuarioAutenticado = Depends(usuario_atual)
) -> dict[str, list[str]]:
    _exigir_tutor(usuario)
    return {"topicosSugeridos": gerar_rascunho_curso(body.titulo, body.nivel)}


# ---------------------------------------------------------------------------
# POST /cursos  (criacao pelo tutor - publicacao direta, sem moderacao)
# ---------------------------------------------------------------------------
class CriarCursoBody(BaseModel):
    titulo: str
    descricao: str = ""
    nivel: str = "BASICO"
    cargaHoraria: int = 0
    topicosModulos: list[str] = []


@app.post("/cursos", status_code=201)
def criar_curso(
    body: CriarCursoBody,
    usuario: UsuarioAutenticado = Depends(usuario_atual),
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    _exigir_tutor(usuario)
    if not body.titulo.strip():
        raise HTTPException(status_code=422, detail="Título é obrigatório")

    curso = CursoORM(
        titulo=body.titulo,
        descricao=body.descricao,
        nivel=body.nivel,
        carga_horaria=body.cargaHoraria,
        total_modulos=len(body.topicosModulos),
        topicos_modulos=body.topicosModulos,
        autor_id=usuario.id,
        origem="COMUNIDADE",
        status="PUBLICADO",
    )
    db.add(curso)
    db.commit()
    db.refresh(curso)
    return curso.as_dict()


# ---------------------------------------------------------------------------
# GET /cursos/meus  (cursos do proprio tutor, incluindo rascunhos)
# ---------------------------------------------------------------------------
@app.get("/cursos/meus")
def meus_cursos(
    usuario: UsuarioAutenticado = Depends(usuario_atual), db: Session = Depends(get_db)
) -> list[dict[str, Any]]:
    cursos = db.query(CursoORM).filter(CursoORM.autor_id == usuario.id).all()
    return [c.as_dict() for c in cursos]


# ---------------------------------------------------------------------------
# Forum (perguntas e respostas da comunidade)
# ---------------------------------------------------------------------------
class CriarPerguntaBody(BaseModel):
    titulo: str
    corpo: str


@app.post("/forum/perguntas", status_code=201)
def criar_pergunta(
    body: CriarPerguntaBody,
    usuario: UsuarioAutenticado = Depends(usuario_atual),
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    if not body.titulo.strip() or not body.corpo.strip():
        raise HTTPException(status_code=422, detail="Título e corpo são obrigatórios")
    pergunta = PerguntaForumORM(autor_id=usuario.id, titulo=body.titulo, corpo=body.corpo)
    db.add(pergunta)
    db.commit()
    db.refresh(pergunta)
    return pergunta.as_dict()


@app.get("/forum/perguntas")
def listar_perguntas(
    _: UsuarioAutenticado = Depends(usuario_atual), db: Session = Depends(get_db)
) -> list[dict[str, Any]]:
    perguntas = db.query(PerguntaForumORM).order_by(PerguntaForumORM.criado_em.desc()).all()
    return [
        p.as_dict(total_respostas=db.query(RespostaForumORM)
                  .filter(RespostaForumORM.pergunta_id == p.id).count())
        for p in perguntas
    ]


@app.get("/forum/perguntas/{pergunta_id}")
def detalhe_pergunta(
    pergunta_id: int, _: UsuarioAutenticado = Depends(usuario_atual), db: Session = Depends(get_db)
) -> dict[str, Any]:
    pergunta = db.query(PerguntaForumORM).filter(PerguntaForumORM.id == pergunta_id).first()
    if pergunta is None:
        raise HTTPException(status_code=404, detail="Pergunta não encontrada")
    respostas = (
        db.query(RespostaForumORM)
        .filter(RespostaForumORM.pergunta_id == pergunta_id)
        .order_by(RespostaForumORM.criado_em)
        .all()
    )
    return {**pergunta.as_dict(total_respostas=len(respostas)), "respostas": [r.as_dict() for r in respostas]}


class CriarRespostaBody(BaseModel):
    corpo: str


@app.post("/forum/perguntas/{pergunta_id}/respostas", status_code=201)
def responder_pergunta(
    pergunta_id: int,
    body: CriarRespostaBody,
    usuario: UsuarioAutenticado = Depends(usuario_atual),
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    if db.query(PerguntaForumORM).filter(PerguntaForumORM.id == pergunta_id).first() is None:
        raise HTTPException(status_code=404, detail="Pergunta não encontrada")
    if not body.corpo.strip():
        raise HTTPException(status_code=422, detail="Resposta não pode ser vazia")
    resposta = RespostaForumORM(pergunta_id=pergunta_id, autor_id=usuario.id, corpo=body.corpo)
    db.add(resposta)
    db.commit()
    db.refresh(resposta)
    return resposta.as_dict()


# ---------------------------------------------------------------------------
# Gamificacao (baseada nos eventos de uso ja registrados - regra fixa, ver
# heuristics.py::calcular_sequencia_dias)
# ---------------------------------------------------------------------------
def _stats_gamificacao(db: Session, nome_user: str) -> dict[str, int]:
    eventos = db.query(EventoORM).filter(EventoORM.user_id == nome_user).all()
    cursos_concluidos = {e.reference_id for e in eventos if e.tipo == "curso_concluido"}
    sequencia = calcular_sequencia_dias([e.timestamp for e in eventos])
    pontos = len(cursos_concluidos) * 100 + sequencia * 10
    return {"cursosConcluidos": len(cursos_concluidos), "sequenciaDias": sequencia, "pontos": pontos}


@app.get("/gamificacao/{user_id}/resumo")
def resumo_gamificacao(
    user_id: str, usuario: UsuarioAutenticado = Depends(usuario_atual), db: Session = Depends(get_db)
) -> dict[str, int]:
    if usuario.nome_user != user_id:
        raise HTTPException(status_code=403, detail="Você só pode consultar seu próprio resumo")
    return _stats_gamificacao(db, user_id)


@app.get("/gamificacao/ranking")
def ranking_gamificacao(
    _: UsuarioAutenticado = Depends(usuario_atual), db: Session = Depends(get_db)
) -> list[dict[str, Any]]:
    ranking = []
    for u in db.query(UsuarioORM).all():
        stats = _stats_gamificacao(db, u.nome_user)
        if stats["pontos"] > 0:
            ranking.append({"nomeAmigavel": u.nome_amigavel, **stats})
    ranking.sort(key=lambda r: r["pontos"], reverse=True)
    return ranking[:10]


# ---------------------------------------------------------------------------
# GET /metricas/impacto  (numeros da base ATUAL/demo - nao uma alegacao de
# escala real, ver observacao no retorno)
# ---------------------------------------------------------------------------
@app.get("/metricas/impacto")
def metricas_impacto(
    _: UsuarioAutenticado = Depends(usuario_atual), db: Session = Depends(get_db)
) -> dict[str, Any]:
    return {
        "totalUsuarios": db.query(UsuarioORM).count(),
        "totalCursosConcluidos": db.query(EventoORM).filter(EventoORM.tipo == "curso_concluido").count(),
        "totalCursosPublicados": db.query(CursoORM).filter(CursoORM.status == "PUBLICADO").count(),
        "totalCursosComunidade": db.query(CursoORM).filter(CursoORM.origem == "COMUNIDADE").count(),
        "totalPerguntasForum": db.query(PerguntaForumORM).count(),
        "observacao": "Números da base de dados atual (ambiente de demonstração), não uma métrica de escala real.",
    }


# ---------------------------------------------------------------------------
# Modo cuidador (somente leitura - o cuidador acompanha, nunca age em nome
# do idoso). Vinculo direto por codigo, sem fila de aprovacao (mesmo
# principio de MVP ja usado no resto do projeto).
# ---------------------------------------------------------------------------
class VincularCuidadorBody(BaseModel):
    codigoIdoso: str  # o nomeUser do idoso


@app.post("/cuidador/vincular", status_code=201)
def vincular_cuidador(
    body: VincularCuidadorBody,
    usuario: UsuarioAutenticado = Depends(usuario_atual),
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    if body.codigoIdoso == usuario.nome_user:
        raise HTTPException(status_code=422, detail="Você não pode se vincular a si mesmo")
    idoso = db.query(UsuarioORM).filter(UsuarioORM.nome_user == body.codigoIdoso).first()
    if idoso is None:
        raise HTTPException(status_code=404, detail="Código de convite não encontrado")
    ja_vinculado = (
        db.query(VinculoCuidadorORM)
        .filter(VinculoCuidadorORM.cuidador_id == usuario.id, VinculoCuidadorORM.idoso_id == idoso.id)
        .first()
    )
    if ja_vinculado is not None:
        raise HTTPException(status_code=409, detail="Vínculo já existe")

    vinculo = VinculoCuidadorORM(cuidador_id=usuario.id, idoso_id=idoso.id)
    db.add(vinculo)
    db.commit()
    return {"status": "vinculado", "idosoNome": idoso.nome_amigavel}


@app.get("/cuidador/vinculos")
def listar_vinculos_cuidador(
    usuario: UsuarioAutenticado = Depends(usuario_atual), db: Session = Depends(get_db)
) -> list[dict[str, Any]]:
    vinculos = db.query(VinculoCuidadorORM).filter(VinculoCuidadorORM.cuidador_id == usuario.id).all()
    return [
        {"idosoId": v.idoso.nome_user, "idosoNome": v.idoso.nome_amigavel, "vinculadoEm": v.criado_em.isoformat()}
        for v in vinculos
    ]


@app.get("/cuidador/{idoso_id}/resumo")
def resumo_idoso(
    idoso_id: str, usuario: UsuarioAutenticado = Depends(usuario_atual), db: Session = Depends(get_db)
) -> dict[str, Any]:
    idoso = db.query(UsuarioORM).filter(UsuarioORM.nome_user == idoso_id).first()
    if idoso is None:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    vinculo = (
        db.query(VinculoCuidadorORM)
        .filter(VinculoCuidadorORM.cuidador_id == usuario.id, VinculoCuidadorORM.idoso_id == idoso.id)
        .first()
    )
    if vinculo is None:
        raise HTTPException(status_code=403, detail="Você não tem vínculo de cuidador com este usuário")
    return {"idosoNome": idoso.nome_amigavel, **_stats_gamificacao(db, idoso.nome_user)}


# ---------------------------------------------------------------------------
# Indicacao (codigo = o proprio nomeUser, ja unico)
# ---------------------------------------------------------------------------
@app.get("/indicacoes/minhas")
def minhas_indicacoes(
    usuario: UsuarioAutenticado = Depends(usuario_atual), db: Session = Depends(get_db)
) -> dict[str, Any]:
    usuario_orm = db.query(UsuarioORM).filter(UsuarioORM.id == usuario.id).first()
    return {"codigo": usuario_orm.nome_user, "totalIndicacoes": usuario_orm.total_indicacoes}


# ---------------------------------------------------------------------------
# Marketplace de tutores (avaliacao de cursos + perfil publico do tutor)
# ---------------------------------------------------------------------------
class AvaliarCursoBody(BaseModel):
    nota: int
    comentario: str | None = None


@app.post("/cursos/{curso_id}/avaliar", status_code=201)
def avaliar_curso(
    curso_id: int,
    body: AvaliarCursoBody,
    usuario: UsuarioAutenticado = Depends(usuario_atual),
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    if db.query(CursoORM).filter(CursoORM.id == curso_id).first() is None:
        raise HTTPException(status_code=404, detail="Curso não encontrado")
    if not 1 <= body.nota <= 5:
        raise HTTPException(status_code=422, detail="nota deve estar entre 1 e 5")
    avaliacao = AvaliacaoCursoORM(
        curso_id=curso_id, usuario_id=usuario.id, nota=body.nota, comentario=body.comentario
    )
    db.add(avaliacao)
    db.commit()
    db.refresh(avaliacao)
    return avaliacao.as_dict()


@app.get("/cursos/{curso_id}/avaliacoes")
def listar_avaliacoes_curso(
    curso_id: int, _: UsuarioAutenticado = Depends(usuario_atual), db: Session = Depends(get_db)
) -> list[dict[str, Any]]:
    avaliacoes = db.query(AvaliacaoCursoORM).filter(AvaliacaoCursoORM.curso_id == curso_id).all()
    return [a.as_dict() for a in avaliacoes]


@app.get("/tutores/{autor_id}")
def perfil_tutor(
    autor_id: str, _: UsuarioAutenticado = Depends(usuario_atual), db: Session = Depends(get_db)
) -> dict[str, Any]:
    tutor = db.query(UsuarioORM).filter(UsuarioORM.nome_user == autor_id).first()
    if tutor is None or not tutor.is_tutor:
        raise HTTPException(status_code=404, detail="Tutor não encontrado")
    cursos = (
        db.query(CursoORM)
        .filter(CursoORM.autor_id == tutor.id, CursoORM.status == "PUBLICADO")
        .all()
    )
    notas = [
        a.nota
        for c in cursos
        for a in db.query(AvaliacaoCursoORM).filter(AvaliacaoCursoORM.curso_id == c.id).all()
    ]
    return {
        "nomeAmigavel": tutor.nome_amigavel,
        "totalCursos": len(cursos),
        "cursos": [c.as_dict() for c in cursos],
        "mediaAvaliacao": round(sum(notas) / len(notas), 1) if notas else None,
        "totalAvaliacoes": len(notas),
    }


@app.get("/")
def raiz() -> dict[str, str]:
    return {"status": "ok", "servico": "Digital 360 - AI Logistics Extension API"}
