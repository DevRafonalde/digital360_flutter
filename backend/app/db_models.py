"""Modelos ORM (SQLAlchemy) - substituem as listas Python em memoria."""
from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, JSON, String
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
    pass


def _agora() -> datetime:
    return datetime.now(timezone.utc)


class UsuarioORM(Base):
    __tablename__ = "usuarios"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    nome_user: Mapped[str] = mapped_column(String, unique=True, index=True)
    senha_hash: Mapped[str] = mapped_column(String)
    nome_amigavel: Mapped[str] = mapped_column(String, default="")
    nome_completo: Mapped[str] = mapped_column(String, default="")
    cpf: Mapped[str] = mapped_column(String, default="")
    is_tutor: Mapped[bool] = mapped_column(Boolean, default=False)
    total_indicacoes: Mapped[int] = mapped_column(Integer, default=0)
    aceitou_politica_em: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    criado_em: Mapped[datetime] = mapped_column(DateTime, default=_agora)


class PedidoORM(Base):
    __tablename__ = "pedidos"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    codigo_pedido: Mapped[str] = mapped_column(String)
    produto: Mapped[str] = mapped_column(String)
    tipo_produto: Mapped[str] = mapped_column(String)
    regiao_entrega: Mapped[str] = mapped_column(String)
    distancia_km: Mapped[int] = mapped_column(Integer)
    prazo_prometido: Mapped[str] = mapped_column(String)
    status_atual: Mapped[str] = mapped_column(String)
    parceiro_logistico: Mapped[str] = mapped_column(String)
    estoque_disponivel: Mapped[bool] = mapped_column(Boolean)
    historico_atrasos: Mapped[int] = mapped_column(Integer, default=0)
    reagendamentos: Mapped[int] = mapped_column(Integer, default=0)
    latitude: Mapped[float] = mapped_column(default=0.0)
    longitude: Mapped[float] = mapped_column(default=0.0)

    def as_dict(self) -> dict:
        return {
            "id": self.id,
            "codigoPedido": self.codigo_pedido,
            "produto": self.produto,
            "tipoProduto": self.tipo_produto,
            "regiaoEntrega": self.regiao_entrega,
            "distanciaKm": self.distancia_km,
            "prazoPrometido": self.prazo_prometido,
            "statusAtual": self.status_atual,
            "parceiroLogistico": self.parceiro_logistico,
            "estoqueDisponivel": self.estoque_disponivel,
            "historicoAtrasos": self.historico_atrasos,
            "reagendamentos": self.reagendamentos,
            "latitude": self.latitude,
            "longitude": self.longitude,
        }


class CursoORM(Base):
    __tablename__ = "cursos"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    titulo: Mapped[str] = mapped_column(String)
    descricao: Mapped[str] = mapped_column(String, default="")
    nivel: Mapped[str] = mapped_column(String, default="BASICO")
    carga_horaria: Mapped[int] = mapped_column(Integer, default=0)
    total_modulos: Mapped[int] = mapped_column(Integer, default=0)
    topicos_modulos: Mapped[list] = mapped_column(JSON, default=list)
    autor_id: Mapped[int | None] = mapped_column(ForeignKey("usuarios.id"), nullable=True)
    origem: Mapped[str] = mapped_column(String, default="OFICIAL")  # OFICIAL | COMUNIDADE
    status: Mapped[str] = mapped_column(String, default="PUBLICADO")  # RASCUNHO | PUBLICADO
    criado_em: Mapped[datetime] = mapped_column(DateTime, default=_agora)

    autor: Mapped["UsuarioORM | None"] = relationship()

    def as_dict(self) -> dict:
        return {
            "id": self.id,
            "titulo": self.titulo,
            "descricao": self.descricao,
            "nivel": self.nivel,
            "cargaHoraria": self.carga_horaria,
            "totalModulos": self.total_modulos,
            "topicosModulos": self.topicos_modulos or [],
            "autorId": self.autor.nome_user if self.autor else None,
            "origem": self.origem,
            "status": self.status,
        }


class EventoORM(Base):
    __tablename__ = "eventos"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[str] = mapped_column(String, index=True)
    tipo: Mapped[str] = mapped_column(String)
    reference_id: Mapped[int] = mapped_column(Integer)
    categoria: Mapped[str | None] = mapped_column(String, nullable=True)
    timestamp: Mapped[datetime] = mapped_column(DateTime, default=_agora)


class FeedbackORM(Base):
    __tablename__ = "feedbacks"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    pedido_id: Mapped[int] = mapped_column(Integer)
    nota: Mapped[int] = mapped_column(Integer)
    comentario: Mapped[str | None] = mapped_column(String, nullable=True)
    registrado_em: Mapped[datetime] = mapped_column(DateTime, default=_agora)


class PerguntaForumORM(Base):
    __tablename__ = "perguntas_forum"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    autor_id: Mapped[int] = mapped_column(ForeignKey("usuarios.id"))
    titulo: Mapped[str] = mapped_column(String)
    corpo: Mapped[str] = mapped_column(String)
    criado_em: Mapped[datetime] = mapped_column(DateTime, default=_agora)

    autor: Mapped["UsuarioORM"] = relationship()

    def as_dict(self, total_respostas: int = 0) -> dict:
        return {
            "id": self.id,
            "autorNome": self.autor.nome_amigavel if self.autor else "Anônimo",
            "titulo": self.titulo,
            "corpo": self.corpo,
            "criadoEm": self.criado_em.isoformat(),
            "totalRespostas": total_respostas,
        }


class RespostaForumORM(Base):
    __tablename__ = "respostas_forum"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    pergunta_id: Mapped[int] = mapped_column(ForeignKey("perguntas_forum.id"))
    autor_id: Mapped[int] = mapped_column(ForeignKey("usuarios.id"))
    corpo: Mapped[str] = mapped_column(String)
    criado_em: Mapped[datetime] = mapped_column(DateTime, default=_agora)

    autor: Mapped["UsuarioORM"] = relationship()

    def as_dict(self) -> dict:
        return {
            "id": self.id,
            "autorNome": self.autor.nome_amigavel if self.autor else "Anônimo",
            "corpo": self.corpo,
            "criadoEm": self.criado_em.isoformat(),
        }


class VinculoCuidadorORM(Base):
    """Vinculo somente-leitura entre um cuidador e um idoso/tutelado - o
    cuidador acompanha o progresso, mas nunca age em nome da pessoa (a conta
    do idoso continua sendo dele, com seu proprio login)."""

    __tablename__ = "vinculos_cuidador"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    cuidador_id: Mapped[int] = mapped_column(ForeignKey("usuarios.id"))
    idoso_id: Mapped[int] = mapped_column(ForeignKey("usuarios.id"))
    status: Mapped[str] = mapped_column(String, default="ATIVO")  # ATIVO (vinculo direto, sem fila)
    criado_em: Mapped[datetime] = mapped_column(DateTime, default=_agora)

    cuidador: Mapped["UsuarioORM"] = relationship(foreign_keys=[cuidador_id])
    idoso: Mapped["UsuarioORM"] = relationship(foreign_keys=[idoso_id])


class AvaliacaoCursoORM(Base):
    __tablename__ = "avaliacoes_curso"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    curso_id: Mapped[int] = mapped_column(ForeignKey("cursos.id"))
    usuario_id: Mapped[int] = mapped_column(ForeignKey("usuarios.id"))
    nota: Mapped[int] = mapped_column(Integer)
    comentario: Mapped[str | None] = mapped_column(String, nullable=True)
    criado_em: Mapped[datetime] = mapped_column(DateTime, default=_agora)

    usuario: Mapped["UsuarioORM"] = relationship()

    def as_dict(self) -> dict:
        return {
            "id": self.id,
            "usuarioNome": self.usuario.nome_amigavel if self.usuario else "Anônimo",
            "nota": self.nota,
            "comentario": self.comentario,
            "criadoEm": self.criado_em.isoformat(),
        }
