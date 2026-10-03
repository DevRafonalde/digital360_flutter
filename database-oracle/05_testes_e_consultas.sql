-- =====================================================================
-- Smart HAS / Digital 360 - Fase 6
-- Script 05: Uso pratico das functions e procedures + testes
-- ---------------------------------------------------------------------
-- Execute com F5 (Run Script) no SQL Developer, ou no SQL*Plus.
-- Os comentarios "Esperado:" indicam o resultado correto para os dados
-- do script 02 executado em um banco recem-criado.
-- =====================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED;

-- ---------------------------------------------------------------------
-- PARTE A - Functions integradas a consultas SQL
-- ---------------------------------------------------------------------

-- A1. Painel de risco: indicador + nivel + resumo formatado por pedido
SELECT CD_PEDIDO,
       ST_PEDIDO,
       FN_CALCULA_RISCO(ID_PEDIDO)                 AS SCORE,
       FN_NIVEL_RISCO(FN_CALCULA_RISCO(ID_PEDIDO)) AS NIVEL
  FROM T_SH_PEDIDO
 ORDER BY SCORE DESC;
-- Esperado: 0002=100 CRITICO | 0005=45 MEDIO | 0003=26 MEDIO
--           0004=8 BAIXO     | 0001=0 BAIXO

-- A2. Function em WHERE: somente pedidos que exigem acao (ALTO/CRITICO)
SELECT FN_RESUMO_PEDIDO(ID_PEDIDO) AS RESUMO
  FROM T_SH_PEDIDO
 WHERE FN_NIVEL_RISCO(FN_CALCULA_RISCO(ID_PEDIDO)) IN ('ALTO', 'CRITICO');
-- Esperado: LM-2026-0002 | Tinta acrilica 18L | ATRASADO | Risco 100 (CRITICO)
--           | Prazo 15/06/2026 | Parceiro Total Express

-- A3. Function de indicador por usuario + agregacao (risco medio da carteira)
SELECT u.NM_USUARIO,
       FN_PROGRESSO_MEDIO_USUARIO(u.ID_USUARIO) AS PROGRESSO_MEDIO,
       (SELECT ROUND(AVG(FN_CALCULA_RISCO(p.ID_PEDIDO)), 1)
          FROM T_SH_PEDIDO p
         WHERE p.ID_USUARIO = u.ID_USUARIO)     AS RISCO_MEDIO_PEDIDOS
  FROM T_SH_USUARIO u
 ORDER BY u.ID_USUARIO;
-- Esperado (progresso): Maria 35 | Jose 55 | Ana 75 | Antonio 20 | Lucia 45 | Pedro 0

-- A4. A view que a API Java consome (functions encapsuladas)
SELECT CD_PEDIDO, NR_SCORE_RISCO, DS_NIVEL_RISCO, DS_RESUMO
  FROM V_SH_PEDIDO_RISCO
 ORDER BY ID_PEDIDO;

-- ---------------------------------------------------------------------
-- PARTE B - Procedures
-- ---------------------------------------------------------------------

-- B1. Rotina de monitoramento IoT: gera alertas das leituras criticas
DECLARE
    v_qt NUMBER;
BEGIN
    SP_REGISTRAR_ALERTAS_SENSORES(p_id_pedido => NULL, p_qt_alertas => v_qt);
    DBMS_OUTPUT.PUT_LINE('Alertas de sensor gerados: ' || v_qt);   -- Esperado: 6
    COMMIT;
END;
/

SELECT a.ID_ALERTA, p.CD_PEDIDO, a.DS_NIVEL, a.DS_MENSAGEM
  FROM T_SH_ALERTA a
  JOIN T_SH_PEDIDO p ON p.ID_PEDIDO = a.ID_PEDIDO
 WHERE a.DS_ORIGEM = 'SENSOR'
 ORDER BY a.ID_ALERTA;
-- Esperado: 6 alertas -> 0002: 44.20 ALTO, 52.30 CRITICO | 0004: 68.50 ALTO,
--           74.00 CRITICO | 0003: 3.40 ALTO | 0005: 3.20 CRITICO

-- B1.1 Reexecucao e idempotente: leituras ja processadas nao geram alerta
DECLARE
    v_qt NUMBER;
BEGIN
    SP_REGISTRAR_ALERTAS_SENSORES(NULL, v_qt);
    DBMS_OUTPUT.PUT_LINE('Alertas na reexecucao: ' || v_qt);       -- Esperado: 0
END;
/

-- B2. Motor de risco: recalcula todos os pedidos (LOOP sobre cursor)
--     Na aplicacao, esta mesma procedure e chamada pela API Java.
DECLARE
    v_score  NUMBER;
    v_nivel  VARCHAR2(10);
    v_rec    VARCHAR2(200);
    v_msg    VARCHAR2(200);
BEGIN
    FOR p IN (SELECT ID_PEDIDO, CD_PEDIDO FROM T_SH_PEDIDO ORDER BY ID_PEDIDO) LOOP
        SP_RECALCULAR_RISCO(p.ID_PEDIDO, v_score, v_nivel, v_rec, v_msg);
        DBMS_OUTPUT.PUT_LINE(p.CD_PEDIDO || ' -> ' || v_score || ' ' || v_nivel || ' | ' || v_rec);
    END LOOP;
    COMMIT;
END;
/
-- Esperado: 5 linhas em T_SH_RISCO_HIST e 1 alerta de RISCO (pedido 0002)

-- B2.1 Recalcular de novo nao duplica o alerta de risco aberto
DECLARE
    v_score NUMBER; v_nivel VARCHAR2(10); v_rec VARCHAR2(200); v_msg VARCHAR2(200);
BEGIN
    SP_RECALCULAR_RISCO(2, v_score, v_nivel, v_rec, v_msg);
    COMMIT;
END;
/
SELECT COUNT(*) AS ALERTAS_RISCO_ABERTOS
  FROM T_SH_ALERTA
 WHERE ID_PEDIDO = 2 AND DS_ORIGEM = 'RISCO' AND ST_ALERTA = 'ABERTO';
-- Esperado: 1

SELECT ID_PEDIDO, NR_SCORE, DS_NIVEL, TO_CHAR(DT_CALCULO, 'DD/MM/YYYY HH24:MI:SS') AS CALCULADO_EM
  FROM T_SH_RISCO_HIST
 ORDER BY ID_RISCO;
-- Esperado: 6 linhas (5 do loop + 1 do recalculo do pedido 2)

-- B3. Relatorio resumido por usuario (DBMS_OUTPUT + snapshot em tabela)
DECLARE
    v_qt NUMBER;
BEGIN
    SP_GERAR_RELATORIO_USUARIOS(p_id_usuario => NULL, p_qt_linhas => v_qt);
    COMMIT;
END;
/
SELECT u.NM_USUARIO, r.QT_CURSOS, r.VL_PROGRESSO_MEDIO, r.QT_PEDIDOS,
       r.QT_ALERTAS_ABERTOS, r.DS_CLASSIFICACAO
  FROM T_SH_RELATORIO_USUARIO r
  JOIN T_SH_USUARIO u ON u.ID_USUARIO = r.ID_USUARIO
 ORDER BY r.ID_RELATORIO;
-- Esperado:
--   Maria Aparecida Lima   3  35  1  3  EM_PROGRESSO
--   Jose Carlos Pereira    2  55  1  0  EM_PROGRESSO
--   Ana Beatriz Souza      2  75  1  1  ENGAJADO
--   Antonio Ferreira       1  20  1  2  INICIANTE
--   Lucia Helena Costa     1  45  1  1  EM_PROGRESSO
--   Pedro Henrique Alves   0   0  0  0  INICIANTE

-- ---------------------------------------------------------------------
-- PARTE C - Tratamento de excecoes (cada bloco deve exibir o erro tratado)
-- ---------------------------------------------------------------------
BEGIN
    DBMS_OUTPUT.PUT_LINE(FN_CALCULA_RISCO(999));
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('C1 OK -> ' || SQLERRM);   -- ORA-20001
END;
/
BEGIN
    DBMS_OUTPUT.PUT_LINE(FN_NIVEL_RISCO(150));
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('C2 OK -> ' || SQLERRM);   -- ORA-20002
END;
/
DECLARE
    v_qt NUMBER;
BEGIN
    SP_GERAR_RELATORIO_USUARIOS(999, v_qt);
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('C3 OK -> ' || SQLERRM);   -- ORA-20003
END;
/
DECLARE
    v_score NUMBER; v_nivel VARCHAR2(10); v_rec VARCHAR2(200); v_msg VARCHAR2(200);
BEGIN
    SP_RECALCULAR_RISCO(NULL, v_score, v_nivel, v_rec, v_msg);
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('C4 OK -> ' || SQLERRM);   -- ORA-20002
END;
/

-- Objetos criados e validos (Esperado: todos com STATUS = VALID)
SELECT OBJECT_NAME, OBJECT_TYPE, STATUS
  FROM USER_OBJECTS
 WHERE OBJECT_NAME LIKE 'FN_%' OR OBJECT_NAME LIKE 'SP_%' OR OBJECT_NAME LIKE 'V_SH_%'
 ORDER BY OBJECT_TYPE, OBJECT_NAME;
