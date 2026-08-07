"""Autenticacao real: hash de senha (bcrypt direto - passlib tem
incompatibilidade conhecida com bcrypt>=4.1) e JWT (pyjwt) com access+refresh
token amarrados ao usuario. Substitui o `_exigir_bearer` anterior, que so
checava se o header nao estava vazio.
"""
from __future__ import annotations

import os
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone

import bcrypt
import jwt
from fastapi import Depends, Header, HTTPException
from sqlalchemy.orm import Session

from .db import get_db
from .db_models import UsuarioORM

# Em producao isso DEVE vir de uma variavel de ambiente real. O fallback
# abaixo e so pra este ambiente de demo/avaliacao continuar rodando sem
# configuracao extra - nunca deveria ser usado silenciosamente em producao.
_JWT_SECRET_ENV = os.environ.get("JWT_SECRET")
if _JWT_SECRET_ENV is None:
    JWT_SECRET = "dev-secret-INSEGURO-defina-JWT_SECRET-em-producao"
else:
    JWT_SECRET = _JWT_SECRET_ENV

JWT_ALGORITHM = "HS256"
ACCESS_TOKEN_MINUTOS = 30
REFRESH_TOKEN_DIAS = 7


def hash_senha(senha: str) -> str:
    return bcrypt.hashpw(senha.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verificar_senha(senha: str, senha_hash: str) -> bool:
    try:
        return bcrypt.checkpw(senha.encode("utf-8"), senha_hash.encode("utf-8"))
    except ValueError:
        return False


def _criar_token(usuario_id: int, nome_user: str, token_type: str, expira_em: timedelta) -> str:
    payload = {
        "sub": nome_user,
        "uid": usuario_id,
        "type": token_type,
        "exp": datetime.now(timezone.utc) + expira_em,
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)


def criar_access_token(usuario_id: int, nome_user: str) -> str:
    return _criar_token(usuario_id, nome_user, "access", timedelta(minutes=ACCESS_TOKEN_MINUTOS))


def criar_refresh_token(usuario_id: int, nome_user: str) -> str:
    return _criar_token(usuario_id, nome_user, "refresh", timedelta(days=REFRESH_TOKEN_DIAS))


def decodificar_token(token: str, tipo_esperado: str) -> dict:
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expirado")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Token inválido")
    if payload.get("type") != tipo_esperado:
        raise HTTPException(status_code=401, detail="Tipo de token inválido")
    return payload


@dataclass
class UsuarioAutenticado:
    id: int
    nome_user: str
    is_tutor: bool


def usuario_atual(
    authorization: str | None = Header(default=None),
    db: Session = Depends(get_db),
) -> UsuarioAutenticado:
    """Dependency que substitui o antigo `_exigir_bearer` - agora decodifica
    e valida um JWT de verdade, e devolve a identidade real do usuario."""
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Token de autenticação ausente")
    token = authorization.split(" ", 1)[1].strip()
    payload = decodificar_token(token, "access")

    usuario = db.query(UsuarioORM).filter(UsuarioORM.id == payload["uid"]).first()
    if usuario is None:
        raise HTTPException(status_code=401, detail="Usuário não encontrado")
    return UsuarioAutenticado(id=usuario.id, nome_user=usuario.nome_user, is_tutor=usuario.is_tutor)
