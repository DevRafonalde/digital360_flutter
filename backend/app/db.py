"""Configuracao do banco (SQLite) - substitui as listas em memoria que
reiniciavam a cada restart do servidor. Dois modos:
- normal: arquivo `app/data/digital360.db` (persistente entre execucoes)
- testes: `sqlite:///:memory:` compartilhado via StaticPool, pra cada teste
  rodar isolado numa transacao que e desfeita no final (ver conftest.py)
"""
from __future__ import annotations

import os
from pathlib import Path

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from .db_models import Base

_DATA_DIR = Path(__file__).parent / "data"
_DATA_DIR.mkdir(exist_ok=True)
_DEFAULT_URL = f"sqlite:///{_DATA_DIR / 'digital360.db'}"

DATABASE_URL = os.environ.get("DATABASE_URL", _DEFAULT_URL)

if DATABASE_URL.endswith(":memory:"):
    engine = create_engine(
        DATABASE_URL,
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
else:
    engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def criar_tabelas() -> None:
    Base.metadata.create_all(bind=engine)


def seed_if_empty(db) -> None:
    """Popula pedidos e catalogo (cursos/servicos oficiais) na primeira vez -
    mesmos dados que ja existiam como listas Python, agora como linhas."""
    from .db_models import CursoORM, PedidoORM

    if db.query(PedidoORM).count() == 0:
        pedidos_seed = [
            dict(
                codigo_pedido="LM-2026-0001", produto="Kit ferramentas basicas",
                tipo_produto="Ferramentas", regiao_entrega="Sao Paulo - Centro",
                distancia_km=8, prazo_prometido="16/06/2026", status_atual="EM_TRANSITO",
                parceiro_logistico="Loggi", estoque_disponivel=True,
                historico_atrasos=0, reagendamentos=0, latitude=-23.5505, longitude=-46.6333,
            ),
            dict(
                codigo_pedido="LM-2026-0002", produto="Tinta acrilica 18L",
                tipo_produto="Pintura", regiao_entrega="Sao Paulo - Zona Leste",
                distancia_km=22, prazo_prometido="15/06/2026", status_atual="ATRASADO",
                parceiro_logistico="Total Express", estoque_disponivel=False,
                historico_atrasos=3, reagendamentos=2, latitude=-23.5400, longitude=-46.4900,
            ),
            dict(
                codigo_pedido="LM-2026-0003", produto="Furadeira de impacto",
                tipo_produto="Ferramentas eletricas", regiao_entrega="Sao Paulo - Zona Sul",
                distancia_km=14, prazo_prometido="18/06/2026", status_atual="PENDENTE",
                parceiro_logistico="Correios", estoque_disponivel=True,
                historico_atrasos=1, reagendamentos=0, latitude=-23.6500, longitude=-46.7000,
            ),
            dict(
                codigo_pedido="LM-2026-0004", produto="Piso laminado (10 caixas)",
                tipo_produto="Revestimento", regiao_entrega="Sao Paulo - Zona Norte",
                distancia_km=19, prazo_prometido="14/06/2026", status_atual="ENTREGUE",
                parceiro_logistico="Loggi", estoque_disponivel=True,
                historico_atrasos=0, reagendamentos=0, latitude=-23.4800, longitude=-46.6200,
            ),
        ]
        for p in pedidos_seed:
            db.add(PedidoORM(**p))

    if db.query(CursoORM).count() == 0:
        cursos_seed = [
            dict(titulo="Primeiros passos no celular",
                 descricao="Aprenda a usar o smartphone com segurança e confiança.",
                 nivel="BASICO", carga_horaria=4, total_modulos=6,
                 topicos_modulos=["Introdução", "Passo a passo", "Erros comuns", "Prática"],
                 origem="OFICIAL", status="PUBLICADO"),
            dict(titulo="Usando o gov.br",
                 descricao="Acesse serviços públicos digitais sem complicação.",
                 nivel="INTERMEDIARIO", carga_horaria=6, total_modulos=8,
                 topicos_modulos=["Introdução", "Passo a passo", "Erros comuns", "Prática"],
                 origem="OFICIAL", status="PUBLICADO"),
            dict(titulo="Segurança digital e golpes",
                 descricao="Identifique fraudes e proteja seus dados pessoais.",
                 nivel="INTERMEDIARIO", carga_horaria=5, total_modulos=7,
                 topicos_modulos=["Introdução", "Passo a passo", "Erros comuns", "Prática"],
                 origem="OFICIAL", status="PUBLICADO"),
            dict(titulo="Pix e pagamentos digitais",
                 descricao="Faça transferências e pagamentos com tranquilidade.",
                 nivel="AVANCADO", carga_horaria=8, total_modulos=10,
                 topicos_modulos=["Introdução", "Passo a passo", "Erros comuns", "Prática"],
                 origem="OFICIAL", status="PUBLICADO"),
        ]
        for c in cursos_seed:
            db.add(CursoORM(**c))

    db.commit()
