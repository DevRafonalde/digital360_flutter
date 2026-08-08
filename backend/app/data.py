"""Catalogo de referencia do motor de recomendacao/tendencias.

Os pedidos e cursos "de verdade" agora moram no banco (SQLite, ver db.py/
db_models.py) - isso aqui e so a lista estatica que o motor heuristico usa
pra saber o titulo/nivel/categoria de cada item ao montar uma recomendacao
(heuristics.py::recomendar), sem precisar fazer join com o banco.
"""
from __future__ import annotations

from typing import Any

CATALOGO: list[dict[str, Any]] = [
    {"tipo": "curso", "id": 1, "titulo": "Primeiros passos no celular", "nivel": "BASICO"},
    {"tipo": "curso", "id": 2, "titulo": "Usando o gov.br", "nivel": "INTERMEDIARIO"},
    {"tipo": "curso", "id": 3, "titulo": "Seguranca digital e golpes", "nivel": "INTERMEDIARIO"},
    {"tipo": "curso", "id": 4, "titulo": "Pix e pagamentos digitais", "nivel": "AVANCADO"},
    {"tipo": "servico", "id": 1, "titulo": "Consultar beneficio do INSS", "categoria": "Previdencia"},
    {"tipo": "servico", "id": 2, "titulo": "Agendar consulta no SUS", "categoria": "Saude"},
    {"tipo": "servico", "id": 3, "titulo": "Emitir 2a via do RG/CPF", "categoria": "Documentos"},
    {"tipo": "servico", "id": 4, "titulo": "Consultar Bolsa Familia", "categoria": "Assistencia Social"},
]
