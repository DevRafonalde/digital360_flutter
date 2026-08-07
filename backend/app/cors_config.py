"""CORS restrito - antes era allow_origins=["*"] (liberado pra qualquer
origem). Agora usa uma lista explicita, configuravel via env var
ALLOWED_ORIGINS (separada por virgula), com um default seguro pra
desenvolvimento local.
"""
import os

_DEFAULT_ORIGINS = [
    "http://localhost",
    "http://localhost:8080",
    "http://127.0.0.1",
    "http://127.0.0.1:8080",
]


def allowed_origins() -> list[str]:
    env = os.environ.get("ALLOWED_ORIGINS")
    if env:
        return [origin.strip() for origin in env.split(",") if origin.strip()]
    return _DEFAULT_ORIGINS
