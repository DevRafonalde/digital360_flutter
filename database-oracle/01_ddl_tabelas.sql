-- =====================================================================
-- Smart HAS / Digital 360 - Fase 6 - Banco de Dados na Sociedade 5.0
-- Script 01: Modelo fisico (DDL) - Oracle 11g ou superior
-- ---------------------------------------------------------------------
-- Ordem de execucao: 01 -> 02 -> 03 -> 04 -> 05
-- Para recriar do zero, execute antes o 99_drop_all.sql
-- Observacao: textos sem acentuacao para evitar problemas de charset
-- entre ferramentas (SQL Developer, SQL*Plus, Live SQL).
-- =====================================================================

-- ---------------------------------------------------------------------
-- Sequences (os dados simulados usam IDs fixos < 1000; a aplicacao
-- Java usa as sequences a partir de 1000)
-- ---------------------------------------------------------------------
CREATE SEQUENCE SEQ_SH_USUARIO   START WITH 1000 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_SH_PEDIDO    START WITH 1000 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_SH_LEITURA   START WITH 1000 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_SH_ALERTA    START WITH 1000 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_SH_RISCO     START WITH 1000 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_SH_RELATORIO START WITH 1000 INCREMENT BY 1 NOCACHE;

-- ---------------------------------------------------------------------
-- 1. Usuario do app Digital 360 (publico: idosos, baixo letramento)
-- ---------------------------------------------------------------------
CREATE TABLE T_SH_USUARIO (
    ID_USUARIO     NUMBER(10)    CONSTRAINT PK_SH_USUARIO PRIMARY KEY,
    NM_USUARIO     VARCHAR2(100) NOT NULL,
    NM_LOGIN       VARCHAR2(30)  NOT NULL CONSTRAINT UK_SH_USUARIO_LOGIN UNIQUE,
    NR_CPF         CHAR(11)      NOT NULL CONSTRAINT UK_SH_USUARIO_CPF UNIQUE,
    DT_NASCIMENTO  DATE          NOT NULL,
    DS_PERFIL      VARCHAR2(20)  NOT NULL
        CONSTRAINT CK_SH_USUARIO_PERFIL CHECK (DS_PERFIL IN ('IDOSO','ADULTO','ESTUDANTE','TUTOR')),
    NM_REGIAO      VARCHAR2(60),
    DT_CADASTRO    DATE DEFAULT SYSDATE NOT NULL
);

-- ---------------------------------------------------------------------
-- 2. Trilhas de aprendizagem (cursos)
-- ---------------------------------------------------------------------
CREATE TABLE T_SH_CURSO (
    ID_CURSO          NUMBER(10)    CONSTRAINT PK_SH_CURSO PRIMARY KEY,
    DS_TITULO         VARCHAR2(100) NOT NULL,
    DS_NIVEL          VARCHAR2(15)  NOT NULL
        CONSTRAINT CK_SH_CURSO_NIVEL CHECK (DS_NIVEL IN ('BASICO','INTERMEDIARIO','AVANCADO')),
    NR_CARGA_HORARIA  NUMBER(4)     NOT NULL CONSTRAINT CK_SH_CURSO_CARGA CHECK (NR_CARGA_HORARIA > 0),
    NR_TOTAL_MODULOS  NUMBER(4)     NOT NULL CONSTRAINT CK_SH_CURSO_MODULOS CHECK (NR_TOTAL_MODULOS > 0)
);

-- ---------------------------------------------------------------------
-- 3. Matricula: usuario x curso (N:N) com progresso
-- ---------------------------------------------------------------------
CREATE TABLE T_SH_MATRICULA (
    ID_MATRICULA  NUMBER(10) CONSTRAINT PK_SH_MATRICULA PRIMARY KEY,
    ID_USUARIO    NUMBER(10) NOT NULL CONSTRAINT FK_SH_MATRIC_USUARIO REFERENCES T_SH_USUARIO (ID_USUARIO),
    ID_CURSO      NUMBER(10) NOT NULL CONSTRAINT FK_SH_MATRIC_CURSO   REFERENCES T_SH_CURSO (ID_CURSO),
    NR_PROGRESSO  NUMBER(3)  DEFAULT 0 NOT NULL
        CONSTRAINT CK_SH_MATRIC_PROGRESSO CHECK (NR_PROGRESSO BETWEEN 0 AND 100),
    DT_INICIO     DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT UK_SH_MATRIC_USU_CURSO UNIQUE (ID_USUARIO, ID_CURSO)
);

-- ---------------------------------------------------------------------
-- 4. Guia de servicos publicos
-- ---------------------------------------------------------------------
CREATE TABLE T_SH_SERVICO (
    ID_SERVICO    NUMBER(10)    CONSTRAINT PK_SH_SERVICO PRIMARY KEY,
    DS_TITULO     VARCHAR2(100) NOT NULL,
    DS_CATEGORIA  VARCHAR2(40)  NOT NULL,
    NM_ORGAO      VARCHAR2(40)  NOT NULL
);

-- ---------------------------------------------------------------------
-- 5. Favoritos: usuario x servico (N:N, PK composta)
-- ---------------------------------------------------------------------
CREATE TABLE T_SH_FAVORITO (
    ID_USUARIO   NUMBER(10) NOT NULL CONSTRAINT FK_SH_FAV_USUARIO REFERENCES T_SH_USUARIO (ID_USUARIO),
    ID_SERVICO   NUMBER(10) NOT NULL CONSTRAINT FK_SH_FAV_SERVICO REFERENCES T_SH_SERVICO (ID_SERVICO),
    DT_FAVORITO  DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK_SH_FAVORITO PRIMARY KEY (ID_USUARIO, ID_SERVICO)
);

-- ---------------------------------------------------------------------
-- 6. Pedido monitorado pela AI Logistics Extension (Leroy Merlin)
-- ---------------------------------------------------------------------
CREATE TABLE T_SH_PEDIDO (
    ID_PEDIDO          NUMBER(10)    CONSTRAINT PK_SH_PEDIDO PRIMARY KEY,
    CD_PEDIDO          VARCHAR2(20)  NOT NULL CONSTRAINT UK_SH_PEDIDO_CODIGO UNIQUE,
    ID_USUARIO         NUMBER(10)    NOT NULL CONSTRAINT FK_SH_PEDIDO_USUARIO REFERENCES T_SH_USUARIO (ID_USUARIO),
    DS_PRODUTO         VARCHAR2(100) NOT NULL,
    DS_TIPO_PRODUTO    VARCHAR2(40)  NOT NULL,
    DS_REGIAO_ENTREGA  VARCHAR2(60)  NOT NULL,
    NR_DISTANCIA_KM    NUMBER(5)     NOT NULL CONSTRAINT CK_SH_PEDIDO_DIST CHECK (NR_DISTANCIA_KM >= 0),
    DT_PRAZO           DATE          NOT NULL,
    ST_PEDIDO          VARCHAR2(15)  NOT NULL
        CONSTRAINT CK_SH_PEDIDO_STATUS CHECK (ST_PEDIDO IN ('PENDENTE','EM_TRANSITO','ENTREGUE','ATRASADO')),
    NM_PARCEIRO        VARCHAR2(40)  NOT NULL,
    FL_ESTOQUE         CHAR(1)       DEFAULT 'S' NOT NULL CONSTRAINT CK_SH_PEDIDO_ESTOQUE CHECK (FL_ESTOQUE IN ('S','N')),
    NR_HIST_ATRASOS    NUMBER(3)     DEFAULT 0 NOT NULL CONSTRAINT CK_SH_PEDIDO_ATRASOS CHECK (NR_HIST_ATRASOS >= 0),
    NR_REAGENDAMENTOS  NUMBER(3)     DEFAULT 0 NOT NULL CONSTRAINT CK_SH_PEDIDO_REAG CHECK (NR_REAGENDAMENTOS >= 0),
    VL_LATITUDE        NUMBER(9,6),
    VL_LONGITUDE       NUMBER(9,6)
);

-- ---------------------------------------------------------------------
-- 7. Sensor IoT embarcado na carga (temperatura, umidade, vibracao)
-- ---------------------------------------------------------------------
CREATE TABLE T_SH_SENSOR (
    ID_SENSOR       NUMBER(10)   CONSTRAINT PK_SH_SENSOR PRIMARY KEY,
    ID_PEDIDO       NUMBER(10)   NOT NULL CONSTRAINT FK_SH_SENSOR_PEDIDO REFERENCES T_SH_PEDIDO (ID_PEDIDO),
    DS_TIPO         VARCHAR2(15) NOT NULL
        CONSTRAINT CK_SH_SENSOR_TIPO CHECK (DS_TIPO IN ('TEMPERATURA','UMIDADE','VIBRACAO')),
    DS_UNIDADE      VARCHAR2(5)  NOT NULL,
    VL_LIMITE_MIN   NUMBER(8,2)  NOT NULL,
    VL_LIMITE_MAX   NUMBER(8,2)  NOT NULL,
    DS_LOCALIZACAO  VARCHAR2(60),
    CONSTRAINT CK_SH_SENSOR_LIMITES CHECK (VL_LIMITE_MAX > VL_LIMITE_MIN)
);

-- ---------------------------------------------------------------------
-- 8. Leituras dos sensores (serie temporal)
-- ---------------------------------------------------------------------
CREATE TABLE T_SH_LEITURA (
    ID_LEITURA     NUMBER(12)  CONSTRAINT PK_SH_LEITURA PRIMARY KEY,
    ID_SENSOR      NUMBER(10)  NOT NULL CONSTRAINT FK_SH_LEITURA_SENSOR REFERENCES T_SH_SENSOR (ID_SENSOR),
    DT_LEITURA     TIMESTAMP   DEFAULT SYSTIMESTAMP NOT NULL,
    VL_LEITURA     NUMBER(8,2) NOT NULL,
    FL_PROCESSADA  CHAR(1)     DEFAULT 'N' NOT NULL CONSTRAINT CK_SH_LEITURA_PROC CHECK (FL_PROCESSADA IN ('S','N'))
);

-- ---------------------------------------------------------------------
-- 9. Alertas (gerados por leitura critica ou por risco logistico)
-- ---------------------------------------------------------------------
CREATE TABLE T_SH_ALERTA (
    ID_ALERTA    NUMBER(12)    CONSTRAINT PK_SH_ALERTA PRIMARY KEY,
    ID_PEDIDO    NUMBER(10)    NOT NULL CONSTRAINT FK_SH_ALERTA_PEDIDO  REFERENCES T_SH_PEDIDO (ID_PEDIDO),
    ID_LEITURA   NUMBER(12)             CONSTRAINT FK_SH_ALERTA_LEITURA REFERENCES T_SH_LEITURA (ID_LEITURA),
    DS_ORIGEM    VARCHAR2(10)  NOT NULL CONSTRAINT CK_SH_ALERTA_ORIGEM CHECK (DS_ORIGEM IN ('SENSOR','RISCO')),
    DS_NIVEL     VARCHAR2(10)  NOT NULL CONSTRAINT CK_SH_ALERTA_NIVEL  CHECK (DS_NIVEL IN ('ALTO','CRITICO')),
    DS_MENSAGEM  VARCHAR2(300) NOT NULL,
    DT_ALERTA    TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    ST_ALERTA    VARCHAR2(10)  DEFAULT 'ABERTO' NOT NULL
        CONSTRAINT CK_SH_ALERTA_STATUS CHECK (ST_ALERTA IN ('ABERTO','RESOLVIDO'))
);

-- ---------------------------------------------------------------------
-- 10. Historico de calculo de risco (auditoria do motor de risco)
-- ---------------------------------------------------------------------
CREATE TABLE T_SH_RISCO_HIST (
    ID_RISCO         NUMBER(12)    CONSTRAINT PK_SH_RISCO_HIST PRIMARY KEY,
    ID_PEDIDO        NUMBER(10)    NOT NULL CONSTRAINT FK_SH_RISCO_PEDIDO REFERENCES T_SH_PEDIDO (ID_PEDIDO),
    NR_SCORE         NUMBER(3)     NOT NULL CONSTRAINT CK_SH_RISCO_SCORE CHECK (NR_SCORE BETWEEN 0 AND 100),
    DS_NIVEL         VARCHAR2(10)  NOT NULL
        CONSTRAINT CK_SH_RISCO_NIVEL CHECK (DS_NIVEL IN ('BAIXO','MEDIO','ALTO','CRITICO')),
    DS_RECOMENDACAO  VARCHAR2(200) NOT NULL,
    DT_CALCULO       TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL
);

-- ---------------------------------------------------------------------
-- 11. Relatorio resumido por usuario (snapshot gerado por procedure)
-- ---------------------------------------------------------------------
CREATE TABLE T_SH_RELATORIO_USUARIO (
    ID_RELATORIO        NUMBER(12)   CONSTRAINT PK_SH_RELATORIO PRIMARY KEY,
    ID_USUARIO          NUMBER(10)   NOT NULL CONSTRAINT FK_SH_RELAT_USUARIO REFERENCES T_SH_USUARIO (ID_USUARIO),
    DT_GERACAO          TIMESTAMP    DEFAULT SYSTIMESTAMP NOT NULL,
    QT_CURSOS           NUMBER(5)    NOT NULL,
    VL_PROGRESSO_MEDIO  NUMBER(5,2)  NOT NULL,
    QT_PEDIDOS          NUMBER(5)    NOT NULL,
    QT_ALERTAS_ABERTOS  NUMBER(5)    NOT NULL,
    DS_CLASSIFICACAO    VARCHAR2(15) NOT NULL
        CONSTRAINT CK_SH_RELAT_CLASSIF CHECK (DS_CLASSIFICACAO IN ('ENGAJADO','EM_PROGRESSO','INICIANTE'))
);

-- ---------------------------------------------------------------------
-- Indices de apoio as consultas e chaves estrangeiras
-- ---------------------------------------------------------------------
CREATE INDEX IX_SH_MATRIC_USUARIO  ON T_SH_MATRICULA (ID_USUARIO);
CREATE INDEX IX_SH_PEDIDO_USUARIO  ON T_SH_PEDIDO (ID_USUARIO);
CREATE INDEX IX_SH_SENSOR_PEDIDO   ON T_SH_SENSOR (ID_PEDIDO);
CREATE INDEX IX_SH_LEITURA_PROC    ON T_SH_LEITURA (FL_PROCESSADA, ID_SENSOR);
CREATE INDEX IX_SH_ALERTA_PEDIDO   ON T_SH_ALERTA (ID_PEDIDO, ST_ALERTA);
CREATE INDEX IX_SH_RISCO_PEDIDO    ON T_SH_RISCO_HIST (ID_PEDIDO, DT_CALCULO);

-- Comentarios de dicionario (documentacao no proprio banco)
COMMENT ON TABLE T_SH_USUARIO           IS 'Usuarios do app Digital 360 (Smart HAS)';
COMMENT ON TABLE T_SH_CURSO             IS 'Trilhas de aprendizagem de inclusao digital';
COMMENT ON TABLE T_SH_MATRICULA         IS 'Progresso do usuario em cada trilha';
COMMENT ON TABLE T_SH_SERVICO           IS 'Guia de servicos publicos (INSS, SUS, gov.br)';
COMMENT ON TABLE T_SH_FAVORITO          IS 'Servicos favoritados pelo usuario';
COMMENT ON TABLE T_SH_PEDIDO            IS 'Pedidos monitorados pela AI Logistics Extension';
COMMENT ON TABLE T_SH_SENSOR            IS 'Sensores IoT embarcados na carga do pedido';
COMMENT ON TABLE T_SH_LEITURA           IS 'Leituras (telemetria) dos sensores';
COMMENT ON TABLE T_SH_ALERTA            IS 'Alertas por leitura critica ou risco logistico';
COMMENT ON TABLE T_SH_RISCO_HIST        IS 'Historico de calculos do motor de risco';
COMMENT ON TABLE T_SH_RELATORIO_USUARIO IS 'Relatorio resumido de engajamento/consumo por usuario';
