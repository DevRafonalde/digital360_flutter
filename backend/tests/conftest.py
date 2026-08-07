"""Fixtures compartilhadas dos testes do backend.

Isolamento real por teste: cada teste roda numa transacao propria (SQLite em
memoria) que e desfeita no final - substitui a suite anterior, que
compartilhava uma unica lista Python em memoria entre todos os testes da
sessao (a ponto de um teste precisar escolher deliberadamente "o pedido 3"
so pra nao interferir nas asserções de outro teste sobre o pedido 2).
"""
import os

os.environ["TESTING"] = "1"

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.db import get_db, seed_if_empty
from app.db_models import Base
from app.main import app

_engine = create_engine(
    "sqlite:///:memory:",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
Base.metadata.create_all(bind=_engine)
_TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=_engine)


@pytest.fixture()
def db_session():
    """Uma sessao por teste, numa transacao que e sempre desfeita (rollback)
    no final - nenhum teste ve dado deixado por outro."""
    connection = _engine.connect()
    transaction = connection.begin()
    session = _TestingSessionLocal(bind=connection)

    seed_if_empty(session)

    try:
        yield session
    finally:
        session.close()
        transaction.rollback()
        connection.close()


@pytest.fixture()
def client(db_session):
    from fastapi.testclient import TestClient

    def _override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = _override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


@pytest.fixture()
def auth_headers(client):
    """Registra e loga um usuario de teste de verdade (via os endpoints reais
    de auth), devolvendo um header Authorization com um access token real -
    substitui o antigo `AUTH = {"Authorization": "Bearer teste-token"}`."""
    client.post(
        "/auth/usuarios/registrar",
        json={
            "nomeUser": "usuario_teste",
            "senhaUser": "senha-teste-123",
            "nomeAmigavel": "Usuário Teste",
            "aceitouPolitica": True,
        },
    )
    resp = client.post(
        "/auth/usuarios/login",
        json={"nomeUser": "usuario_teste", "senhaUser": "senha-teste-123"},
    )
    token = resp.json()["accessToken"]
    return {"Authorization": f"Bearer {token}"}
