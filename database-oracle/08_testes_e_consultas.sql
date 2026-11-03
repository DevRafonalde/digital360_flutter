-- =====================================================================
-- Smart HAS / Digital 360 - Consolidacao
-- Script 08: Demonstracao de uso dos packages, Dynamic SQL e triggers
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
       PKG_SH_RISCO.FN_CALCULA_RISCO(ID_PEDIDO)                 AS SCORE,
       PKG_SH_RISCO.FN_NIVEL_RISCO(PKG_SH_RISCO.FN_CALCULA_RISCO(ID_PEDIDO)) AS NIVEL
  FROM T_SH_PEDIDO
 ORDER BY SCORE DESC;
-- Esperado: 0002=100 CRITICO | 0005=45 MEDIO | 0003=26 MEDIO
--           0004=8 BAIXO     | 0001=0 BAIXO

-- A2. Function em WHERE: somente pedidos que exigem acao (ALTO/CRITICO)
SELECT PKG_SH_RISCO.FN_RESUMO_PEDIDO(ID_PEDIDO) AS RESUMO
  FROM T_SH_PEDIDO
 WHERE PKG_SH_RISCO.FN_NIVEL_RISCO(PKG_SH_RISCO.FN_CALCULA_RISCO(ID_PEDIDO)) IN ('ALTO', 'CRITICO');
-- Esperado: LM-2026-0002 | Tinta acrilica 18L | ATRASADO | Risco 100 (CRITICO)
--           | Prazo 15/06/2026 | Parceiro Total Express

-- A3. Function de indicador por usuario + agregacao (risco medio da carteira)
SELECT u.NM_USUARIO,
       PKG_SH_USUARIO.FN_PROGRESSO_MEDIO_USUARIO(u.ID_USUARIO) AS PROGRESSO_MEDIO,
       (SELECT ROUND(AVG(PKG_SH_RISCO.FN_CALCULA_RISCO(p.ID_PEDIDO)), 1)
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
    PKG_SH_IOT.SP_REGISTRAR_ALERTAS_SENSORES(p_id_pedido => NULL, p_qt_alertas => v_qt);
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
    PKG_SH_IOT.SP_REGISTRAR_ALERTAS_SENSORES(NULL, v_qt);
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
        PKG_SH_RISCO.SP_RECALCULAR_RISCO(p.ID_PEDIDO, v_score, v_nivel, v_rec, v_msg);
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
    PKG_SH_RISCO.SP_RECALCULAR_RISCO(2, v_score, v_nivel, v_rec, v_msg);
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
    PKG_SH_USUARIO.SP_GERAR_RELATORIO_USUARIOS(p_id_usuario => NULL, p_qt_linhas => v_qt);
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
    DBMS_OUTPUT.PUT_LINE(PKG_SH_RISCO.FN_CALCULA_RISCO(999));
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('C1 OK -> ' || SQLERRM);   -- ORA-20001
END;
/
BEGIN
    DBMS_OUTPUT.PUT_LINE(PKG_SH_RISCO.FN_NIVEL_RISCO(150));
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('C2 OK -> ' || SQLERRM);   -- ORA-20002
END;
/
DECLARE
    v_qt NUMBER;
BEGIN
    PKG_SH_USUARIO.SP_GERAR_RELATORIO_USUARIOS(999, v_qt);
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('C3 OK -> ' || SQLERRM);   -- ORA-20003
END;
/
DECLARE
    v_score NUMBER; v_nivel VARCHAR2(10); v_rec VARCHAR2(200); v_msg VARCHAR2(200);
BEGIN
    PKG_SH_RISCO.SP_RECALCULAR_RISCO(NULL, v_score, v_nivel, v_rec, v_msg);
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('C4 OK -> ' || SQLERRM);   -- ORA-20002
END;
/

-- ---------------------------------------------------------------------
-- PARTE D - Dynamic SQL (PKG_SH_CONSULTA)
-- ---------------------------------------------------------------------

-- D1. Busca flexivel: so os filtros informados entram no SQL (DBMS_SQL)
VARIABLE rc REFCURSOR;
BEGIN
    :rc := PKG_SH_CONSULTA.FN_BUSCAR_PEDIDOS(p_regiao => 'leste', p_ordenar_por => 'distancia', p_direcao => 'ASC');
END;
/
PRINT rc;
-- Esperado: LM-2026-0002 (22 km) e LM-2026-0005 (25 km)

-- D2. Agrupamento escolhido em tempo de execucao (OPEN FOR dinamico)
BEGIN
    :rc := PKG_SH_CONSULTA.FN_RESUMO_POR_DIMENSAO('parceiro');
END;
/
PRINT rc;
-- Esperado: Total Express 100 | Correios 35.5 | Loggi 4

-- D3. Apelido fora da lista fechada e recusado
DECLARE
    c SYS_REFCURSOR;
BEGIN
    c := PKG_SH_CONSULTA.FN_BUSCAR_PEDIDOS(p_ordenar_por => 'ID_PEDIDO; DROP TABLE T_SH_PEDIDO');
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('D3 OK -> ' || SQLERRM);   -- ORA-20002
END;
/

-- ---------------------------------------------------------------------
-- PARTE E - Triggers de auditoria e automacao
-- ---------------------------------------------------------------------

-- E1. Resolver um alerta manualmente: a trigger grava o UPDATE
DECLARE
    v_alerta T_SH_ALERTA.ID_ALERTA%TYPE;
BEGIN
    SELECT MIN(ID_ALERTA) INTO v_alerta FROM T_SH_ALERTA WHERE ID_PEDIDO = 3;
    PKG_SH_IOT.SP_RESOLVER_ALERTA(v_alerta);
    COMMIT;
END;
/

-- E2. Pedido entregue: a trigger encerra os alertas abertos sozinha
UPDATE T_SH_PEDIDO SET ST_PEDIDO = 'ENTREGUE' WHERE ID_PEDIDO = 5;
COMMIT;
SELECT ID_ALERTA, ID_PEDIDO, ST_ALERTA FROM T_SH_ALERTA WHERE ID_PEDIDO IN (3, 5) ORDER BY ID_ALERTA;
-- Esperado: todos RESOLVIDO

-- E3. Trilha de auditoria: quem, quando, de onde e o que mudou
SELECT ID_ALERTA, ID_PEDIDO, DS_OPERACAO, ST_ANTERIOR, ST_NOVO, NM_USUARIO_BD, NM_MODULO,
       TO_CHAR(DT_EVENTO, 'DD/MM/YYYY HH24:MI:SS') AS EVENTO
  FROM T_SH_ALERTA_AUDITORIA
 WHERE DS_OPERACAO = 'UPDATE'
 ORDER BY ID_AUDITORIA;
-- Esperado: 2 linhas ABERTO -> RESOLVIDO (pedidos 3 e 5)

-- Objetos criados e validos (Esperado: todos com STATUS = VALID)
SELECT OBJECT_NAME, OBJECT_TYPE, STATUS
  FROM USER_OBJECTS
 WHERE OBJECT_TYPE IN ('PACKAGE', 'PACKAGE BODY', 'TRIGGER', 'VIEW')
 ORDER BY OBJECT_TYPE, OBJECT_NAME;
