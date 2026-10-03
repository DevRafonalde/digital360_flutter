-- =====================================================================
-- Smart HAS / Digital 360 - Fase 6
-- Script 03: Functions PL/SQL
-- ---------------------------------------------------------------------
--  FN_NIVEL_RISCO              -> classifica um score (0-100) em nivel
--  FN_CALCULA_RISCO            -> INDICADOR: score de risco de atraso
--  FN_PROGRESSO_MEDIO_USUARIO  -> INDICADOR: progresso medio nas trilhas
--  FN_RESUMO_PEDIDO            -> DADOS FORMATADOS: resumo do pedido
--
-- Codigos de erro padronizados (RAISE_APPLICATION_ERROR):
--  -20001 pedido nao encontrado | -20002 parametro nulo/invalido
--  -20003 usuario nao encontrado
-- Execute no SQL Developer com F5 (Run Script) ou no SQL*Plus.
-- =====================================================================

-- ---------------------------------------------------------------------
-- FN_NIVEL_RISCO
-- Objetivo: converter o score numerico em um nivel de risco legivel.
-- Regra (identica ao motor do app Flutter):
--   >= 75 CRITICO | >= 50 ALTO | >= 25 MEDIO | < 25 BAIXO
-- DETERMINISTIC: mesma entrada sempre gera a mesma saida (pode ser
-- usada em SELECT, WHERE, ORDER BY e indices baseados em funcao).
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION FN_NIVEL_RISCO (
    p_score IN NUMBER
) RETURN VARCHAR2 DETERMINISTIC
IS
    e_score_invalido EXCEPTION;
BEGIN
    IF p_score IS NULL OR p_score < 0 OR p_score > 100 THEN
        RAISE e_score_invalido;
    END IF;

    IF p_score >= 75 THEN
        RETURN 'CRITICO';
    ELSIF p_score >= 50 THEN
        RETURN 'ALTO';
    ELSIF p_score >= 25 THEN
        RETURN 'MEDIO';
    ELSE
        RETURN 'BAIXO';
    END IF;
EXCEPTION
    WHEN e_score_invalido THEN
        RAISE_APPLICATION_ERROR(-20002, 'Score invalido (esperado 0 a 100): ' || NVL(TO_CHAR(p_score), 'NULO'));
END FN_NIVEL_RISCO;
/

-- ---------------------------------------------------------------------
-- FN_CALCULA_RISCO  (function de INDICADOR)
-- Objetivo: calcular o score de risco de atraso (0 a 100) de um pedido,
-- trazendo para o banco a regra que antes existia apenas no app.
-- Pesos:
--   +18 por atraso no historico do parceiro/regiao
--   +12 por reagendamento
--   +25 se nao ha estoque disponivel
--   +15 se distancia > 20 km | +8 se distancia > 10 km
--   +20 se o pedido ja esta ATRASADO
-- O resultado e limitado a 100.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION FN_CALCULA_RISCO (
    p_id_pedido IN T_SH_PEDIDO.ID_PEDIDO%TYPE
) RETURN NUMBER
IS
    v_pedido        T_SH_PEDIDO%ROWTYPE;
    v_score         NUMBER := 0;
    e_param_nulo    EXCEPTION;
BEGIN
    IF p_id_pedido IS NULL THEN
        RAISE e_param_nulo;
    END IF;

    SELECT *
      INTO v_pedido
      FROM T_SH_PEDIDO
     WHERE ID_PEDIDO = p_id_pedido;

    v_score := v_score + (v_pedido.NR_HIST_ATRASOS   * 18);
    v_score := v_score + (v_pedido.NR_REAGENDAMENTOS * 12);

    IF v_pedido.FL_ESTOQUE = 'N' THEN
        v_score := v_score + 25;
    END IF;

    IF v_pedido.NR_DISTANCIA_KM > 20 THEN
        v_score := v_score + 15;
    ELSIF v_pedido.NR_DISTANCIA_KM > 10 THEN
        v_score := v_score + 8;
    END IF;

    IF v_pedido.ST_PEDIDO = 'ATRASADO' THEN
        v_score := v_score + 20;
    END IF;

    RETURN LEAST(v_score, 100);
EXCEPTION
    WHEN e_param_nulo THEN
        RAISE_APPLICATION_ERROR(-20002, 'FN_CALCULA_RISCO: o parametro p_id_pedido nao pode ser nulo.');
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'FN_CALCULA_RISCO: pedido nao encontrado (ID ' || p_id_pedido || ').');
END FN_CALCULA_RISCO;
/

-- ---------------------------------------------------------------------
-- FN_PROGRESSO_MEDIO_USUARIO  (function de INDICADOR)
-- Objetivo: media do progresso (0-100) do usuario nas trilhas em que
-- esta matriculado. Retorna 0 quando o usuario nao tem matriculas.
-- Usada no relatorio resumido por usuario (SP_GERAR_RELATORIO_USUARIOS).
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION FN_PROGRESSO_MEDIO_USUARIO (
    p_id_usuario IN T_SH_USUARIO.ID_USUARIO%TYPE
) RETURN NUMBER
IS
    v_existe     NUMBER;
    v_media      NUMBER;
    e_param_nulo EXCEPTION;
BEGIN
    IF p_id_usuario IS NULL THEN
        RAISE e_param_nulo;
    END IF;

    SELECT COUNT(*) INTO v_existe FROM T_SH_USUARIO WHERE ID_USUARIO = p_id_usuario;
    IF v_existe = 0 THEN
        RAISE NO_DATA_FOUND;
    END IF;

    SELECT NVL(AVG(NR_PROGRESSO), 0)
      INTO v_media
      FROM T_SH_MATRICULA
     WHERE ID_USUARIO = p_id_usuario;

    RETURN ROUND(v_media, 2);
EXCEPTION
    WHEN e_param_nulo THEN
        RAISE_APPLICATION_ERROR(-20002, 'FN_PROGRESSO_MEDIO_USUARIO: o parametro p_id_usuario nao pode ser nulo.');
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20003, 'FN_PROGRESSO_MEDIO_USUARIO: usuario nao encontrado (ID ' || p_id_usuario || ').');
END FN_PROGRESSO_MEDIO_USUARIO;
/

-- ---------------------------------------------------------------------
-- FN_RESUMO_PEDIDO  (function de DADOS FORMATADOS)
-- Objetivo: devolver uma linha pronta para exibicao (app, painel ou
-- notificacao) com codigo, produto, status, risco e prazo.
-- Exemplo de retorno:
--   LM-2026-0002 | Tinta acrilica 18L | ATRASADO | Risco 100 (CRITICO)
--   | Prazo 15/06/2026 | Parceiro Total Express
-- Reutiliza FN_CALCULA_RISCO e FN_NIVEL_RISCO (composicao de functions).
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION FN_RESUMO_PEDIDO (
    p_id_pedido IN T_SH_PEDIDO.ID_PEDIDO%TYPE
) RETURN VARCHAR2
IS
    v_codigo     T_SH_PEDIDO.CD_PEDIDO%TYPE;
    v_produto    T_SH_PEDIDO.DS_PRODUTO%TYPE;
    v_status     T_SH_PEDIDO.ST_PEDIDO%TYPE;
    v_prazo      T_SH_PEDIDO.DT_PRAZO%TYPE;
    v_parceiro   T_SH_PEDIDO.NM_PARCEIRO%TYPE;
    v_score      NUMBER;
    e_param_nulo EXCEPTION;
BEGIN
    IF p_id_pedido IS NULL THEN
        RAISE e_param_nulo;
    END IF;

    SELECT CD_PEDIDO, DS_PRODUTO, ST_PEDIDO, DT_PRAZO, NM_PARCEIRO
      INTO v_codigo, v_produto, v_status, v_prazo, v_parceiro
      FROM T_SH_PEDIDO
     WHERE ID_PEDIDO = p_id_pedido;

    v_score := FN_CALCULA_RISCO(p_id_pedido);

    RETURN v_codigo
        || ' | ' || v_produto
        || ' | ' || v_status
        || ' | Risco ' || v_score || ' (' || FN_NIVEL_RISCO(v_score) || ')'
        || ' | Prazo ' || TO_CHAR(v_prazo, 'DD/MM/YYYY')
        || ' | Parceiro ' || v_parceiro;
EXCEPTION
    WHEN e_param_nulo THEN
        RAISE_APPLICATION_ERROR(-20002, 'FN_RESUMO_PEDIDO: o parametro p_id_pedido nao pode ser nulo.');
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'FN_RESUMO_PEDIDO: pedido nao encontrado (ID ' || p_id_pedido || ').');
END FN_RESUMO_PEDIDO;
/

-- ---------------------------------------------------------------------
-- View de apoio: integra as functions a uma consulta reutilizavel.
-- E a consulta usada pela API Java no endpoint GET /pedidos.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW V_SH_PEDIDO_RISCO AS
SELECT p.ID_PEDIDO,
       p.CD_PEDIDO,
       p.ID_USUARIO,
       p.DS_PRODUTO,
       p.DS_TIPO_PRODUTO,
       p.DS_REGIAO_ENTREGA,
       p.NR_DISTANCIA_KM,
       p.DT_PRAZO,
       p.ST_PEDIDO,
       p.NM_PARCEIRO,
       p.FL_ESTOQUE,
       p.NR_HIST_ATRASOS,
       p.NR_REAGENDAMENTOS,
       p.VL_LATITUDE,
       p.VL_LONGITUDE,
       FN_CALCULA_RISCO(p.ID_PEDIDO)                 AS NR_SCORE_RISCO,
       FN_NIVEL_RISCO(FN_CALCULA_RISCO(p.ID_PEDIDO)) AS DS_NIVEL_RISCO,
       FN_RESUMO_PEDIDO(p.ID_PEDIDO)                 AS DS_RESUMO
  FROM T_SH_PEDIDO p;
