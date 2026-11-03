-- =====================================================================
-- Smart HAS / Digital 360 - Consolidacao
-- Script 09: testes automatizados da camada PL/SQL (usado no pipeline)
-- ---------------------------------------------------------------------
-- Exige uma base recem-instalada (00_instalar.sql). Desfaz tudo no final
-- com ROLLBACK. Se algum teste falhar, levanta -20999, e o pipeline para
-- porque o SQL*Plus roda com WHENEVER SQLERROR EXIT FAILURE.
-- =====================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED;

DECLARE
    v_ok    PLS_INTEGER := 0;
    v_falhas PLS_INTEGER := 0;
    v_num    NUMBER;
    v_score  NUMBER;
    v_nivel  VARCHAR2(10);
    v_rec    VARCHAR2(200);
    v_msg    VARCHAR2(200);
    v_alerta T_SH_ALERTA.ID_ALERTA%TYPE;
    v_rc     SYS_REFCURSOR;
    v_pedido V_SH_PEDIDO_RISCO%ROWTYPE;

    PROCEDURE conferir (p_nome IN VARCHAR2, p_esperado IN VARCHAR2, p_obtido IN VARCHAR2) IS
    BEGIN
        IF p_esperado = p_obtido OR (p_esperado IS NULL AND p_obtido IS NULL) THEN
            v_ok := v_ok + 1;
            DBMS_OUTPUT.PUT_LINE('[OK]    ' || p_nome || ' = ' || p_obtido);
        ELSE
            v_falhas := v_falhas + 1;
            DBMS_OUTPUT.PUT_LINE('[FALHA] ' || p_nome || ': esperado ' || p_esperado || ', obtido ' || p_obtido);
        END IF;
    END conferir;

    FUNCTION contar (p_sql IN VARCHAR2) RETURN NUMBER IS
        v_qt NUMBER;
    BEGIN
        EXECUTE IMMEDIATE p_sql INTO v_qt;
        RETURN v_qt;
    END contar;

    -- Conta as linhas do cursor de pedidos e guarda a primeira em v_pedido
    FUNCTION linhas_pedidos (p_rc IN OUT SYS_REFCURSOR) RETURN NUMBER IS
        v_linha V_SH_PEDIDO_RISCO%ROWTYPE;
        v_qt    NUMBER := 0;
    BEGIN
        LOOP
            FETCH p_rc INTO v_linha;
            EXIT WHEN p_rc%NOTFOUND;
            v_qt := v_qt + 1;
            IF v_qt = 1 THEN
                v_pedido := v_linha;
            END IF;
        END LOOP;
        CLOSE p_rc;
        RETURN v_qt;
    END linhas_pedidos;

    -- Espera que o bloco dinamico levante exatamente o codigo informado
    PROCEDURE conferir_erro (p_nome IN VARCHAR2, p_codigo IN NUMBER, p_bloco IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE 'BEGIN ' || p_bloco || ' END;';
        conferir(p_nome, TO_CHAR(p_codigo), 'nenhum erro');
    EXCEPTION
        WHEN OTHERS THEN
            conferir(p_nome, TO_CHAR(p_codigo), TO_CHAR(SQLCODE));
    END conferir_erro;
BEGIN
    IF contar('SELECT COUNT(*) FROM T_SH_ALERTA') > 0 THEN
        RAISE_APPLICATION_ERROR(-20997, 'Testes exigem base recem-instalada: execute 00_instalar.sql antes.');
    END IF;

    DBMS_OUTPUT.PUT_LINE('--- Objetos ---');
    conferir('package bodies validos', '4', TO_CHAR(contar(
        q'[SELECT COUNT(*) FROM USER_OBJECTS WHERE OBJECT_TYPE = 'PACKAGE BODY' AND OBJECT_NAME LIKE 'PKG_SH_%' AND STATUS = 'VALID']')));
    conferir('triggers ativas', '2', TO_CHAR(contar(
        q'[SELECT COUNT(*) FROM USER_TRIGGERS WHERE TRIGGER_NAME LIKE 'TRG_SH_%' AND STATUS = 'ENABLED']')));
    conferir('functions/procedures soltas', '0', TO_CHAR(contar(
        q'[SELECT COUNT(*) FROM USER_OBJECTS WHERE OBJECT_TYPE IN ('FUNCTION', 'PROCEDURE')]')));

    DBMS_OUTPUT.PUT_LINE('--- PKG_SH_RISCO ---');
    conferir('score pedido 1', '0',   TO_CHAR(PKG_SH_RISCO.FN_CALCULA_RISCO(1)));
    conferir('score pedido 2', '100', TO_CHAR(PKG_SH_RISCO.FN_CALCULA_RISCO(2)));
    conferir('score pedido 3', '26',  TO_CHAR(PKG_SH_RISCO.FN_CALCULA_RISCO(3)));
    conferir('score pedido 4', '8',   TO_CHAR(PKG_SH_RISCO.FN_CALCULA_RISCO(4)));
    conferir('score pedido 5', '45',  TO_CHAR(PKG_SH_RISCO.FN_CALCULA_RISCO(5)));
    conferir('nivel de 75', 'CRITICO', PKG_SH_RISCO.FN_NIVEL_RISCO(75));
    conferir('nivel de 74', 'ALTO',    PKG_SH_RISCO.FN_NIVEL_RISCO(74));
    conferir('nivel de 25', 'MEDIO',   PKG_SH_RISCO.FN_NIVEL_RISCO(25));
    conferir('nivel de 24', 'BAIXO',   PKG_SH_RISCO.FN_NIVEL_RISCO(24));
    conferir_erro('pedido inexistente', -20001, 'DBMS_OUTPUT.PUT_LINE(PKG_SH_RISCO.FN_CALCULA_RISCO(999));');
    conferir_erro('score fora da faixa', -20002, 'DBMS_OUTPUT.PUT_LINE(PKG_SH_RISCO.FN_NIVEL_RISCO(150));');

    PKG_SH_RISCO.SP_RECALCULAR_RISCO(2, v_score, v_nivel, v_rec, v_msg);
    conferir('recalculo do pedido 2', 'CRITICO', v_nivel);
    PKG_SH_RISCO.SP_RECALCULAR_RISCO(2, v_score, v_nivel, v_rec, v_msg);
    conferir('recalculo nao duplica alerta', '1', TO_CHAR(contar(
        q'[SELECT COUNT(*) FROM T_SH_ALERTA WHERE ID_PEDIDO = 2 AND DS_ORIGEM = 'RISCO' AND ST_ALERTA = 'ABERTO']')));
    conferir('historico do recalculo', '2', TO_CHAR(contar('SELECT COUNT(*) FROM T_SH_RISCO_HIST WHERE ID_PEDIDO = 2')));

    DBMS_OUTPUT.PUT_LINE('--- PKG_SH_IOT e auditoria ---');
    PKG_SH_IOT.SP_REGISTRAR_ALERTAS_SENSORES(NULL, v_num);
    conferir('alertas de sensor', '6', TO_CHAR(v_num));
    PKG_SH_IOT.SP_REGISTRAR_ALERTAS_SENSORES(NULL, v_num);
    conferir('reexecucao e idempotente', '0', TO_CHAR(v_num));
    conferir('trigger audita os INSERTs', '7', TO_CHAR(contar(
        q'[SELECT COUNT(*) FROM T_SH_ALERTA_AUDITORIA WHERE DS_OPERACAO = 'INSERT']')));

    SELECT MIN(ID_ALERTA) INTO v_alerta FROM T_SH_ALERTA WHERE ID_PEDIDO = 3;
    PKG_SH_IOT.SP_RESOLVER_ALERTA(v_alerta);
    PKG_SH_IOT.SP_RESOLVER_ALERTA(v_alerta);
    SELECT ST_ALERTA INTO v_msg FROM T_SH_ALERTA WHERE ID_ALERTA = v_alerta;
    conferir('alerta resolvido', 'RESOLVIDO', v_msg);
    conferir('resolver de novo nao gera auditoria', '1', TO_CHAR(contar(
        q'[SELECT COUNT(*) FROM T_SH_ALERTA_AUDITORIA WHERE DS_OPERACAO = 'UPDATE' AND ST_ANTERIOR = 'ABERTO' AND ST_NOVO = 'RESOLVIDO']')));
    conferir_erro('alerta inexistente', -20004, 'PKG_SH_IOT.SP_RESOLVER_ALERTA(999999);');

    DBMS_OUTPUT.PUT_LINE('--- PKG_SH_USUARIO ---');
    conferir('progresso de Maria', '35', TO_CHAR(PKG_SH_USUARIO.FN_PROGRESSO_MEDIO_USUARIO(1)));
    conferir('progresso de Pedro (sem matricula)', '0', TO_CHAR(PKG_SH_USUARIO.FN_PROGRESSO_MEDIO_USUARIO(6)));
    PKG_SH_USUARIO.SP_GERAR_RELATORIO_USUARIOS(NULL, v_num);
    conferir('usuarios no relatorio', '6', TO_CHAR(v_num));
    conferir_erro('usuario inexistente', -20003, 'DBMS_OUTPUT.PUT_LINE(PKG_SH_USUARIO.FN_PROGRESSO_MEDIO_USUARIO(999));');

    DBMS_OUTPUT.PUT_LINE('--- Dynamic SQL (PKG_SH_CONSULTA) ---');
    v_rc := PKG_SH_CONSULTA.FN_BUSCAR_PEDIDOS;
    conferir('sem filtros', '5', TO_CHAR(linhas_pedidos(v_rc)));
    conferir('ordem padrao: maior score primeiro', 'LM-2026-0002', v_pedido.CD_PEDIDO);

    v_rc := PKG_SH_CONSULTA.FN_BUSCAR_PEDIDOS(p_status => 'atrasado');
    conferir('filtro por status', '1', TO_CHAR(linhas_pedidos(v_rc)));

    v_rc := PKG_SH_CONSULTA.FN_BUSCAR_PEDIDOS(p_nivel_risco => 'MEDIO', p_regiao => 'leste');
    conferir('dois filtros combinados', '1', TO_CHAR(linhas_pedidos(v_rc)));
    conferir('resultado dos dois filtros', 'LM-2026-0005', v_pedido.CD_PEDIDO);

    v_rc := PKG_SH_CONSULTA.FN_BUSCAR_PEDIDOS(p_score_min => 26, p_ordenar_por => 'distancia', p_direcao => 'ASC');
    conferir('score minimo', '3', TO_CHAR(linhas_pedidos(v_rc)));
    conferir('ordenacao por distancia', 'LM-2026-0003', v_pedido.CD_PEDIDO);

    v_rc := PKG_SH_CONSULTA.FN_BUSCAR_PEDIDOS(p_regiao => q'[' OR '1'='1]');
    conferir('injection no filtro vira texto comum', '0', TO_CHAR(linhas_pedidos(v_rc)));
    conferir_erro('injection na ordenacao', -20002,
        q'[DECLARE c SYS_REFCURSOR; BEGIN c := PKG_SH_CONSULTA.FN_BUSCAR_PEDIDOS(p_ordenar_por => 'ID_PEDIDO; DROP TABLE T_SH_PEDIDO'); END;]');
    conferir_erro('injection na direcao', -20002,
        q'[DECLARE c SYS_REFCURSOR; BEGIN c := PKG_SH_CONSULTA.FN_BUSCAR_PEDIDOS(p_direcao => 'DESC, (SELECT 1 FROM DUAL)'); END;]');
    conferir_erro('status invalido', -20002,
        q'[DECLARE c SYS_REFCURSOR; BEGIN c := PKG_SH_CONSULTA.FN_BUSCAR_PEDIDOS(p_status => 'XYZ'); END;]');
    conferir_erro('status muito longo', -20002,
        q'[DECLARE c SYS_REFCURSOR; BEGIN c := PKG_SH_CONSULTA.FN_BUSCAR_PEDIDOS(p_status => RPAD('X', 500, 'X')); END;]');
    conferir_erro('dimensao invalida', -20002,
        q'[DECLARE c SYS_REFCURSOR; BEGIN c := PKG_SH_CONSULTA.FN_RESUMO_POR_DIMENSAO('NR_CPF'); END;]');

    DECLARE
        v_grupo VARCHAR2(60);
        v_qt    NUMBER;
        v_media NUMBER;
        v_risco NUMBER;
        v_soma  NUMBER := 0;
    BEGIN
        v_rc := PKG_SH_CONSULTA.FN_RESUMO_POR_DIMENSAO('nivel');
        LOOP
            FETCH v_rc INTO v_grupo, v_qt, v_media, v_risco;
            EXIT WHEN v_rc%NOTFOUND;
            v_soma := v_soma + v_qt;
            IF v_grupo = 'CRITICO' THEN
                conferir('resumo: pedidos em risco no nivel CRITICO', '1', TO_CHAR(v_risco));
            END IF;
        END LOOP;
        CLOSE v_rc;
        conferir('resumo: soma de todos os grupos', '5', TO_CHAR(v_soma));
    END;

    DBMS_OUTPUT.PUT_LINE('--- Trigger de automacao ---');
    conferir('alertas abertos do pedido 2 antes da entrega', '3', TO_CHAR(contar(
        q'[SELECT COUNT(*) FROM T_SH_ALERTA WHERE ID_PEDIDO = 2 AND ST_ALERTA = 'ABERTO']')));
    UPDATE T_SH_PEDIDO SET ST_PEDIDO = 'ENTREGUE' WHERE ID_PEDIDO = 2;
    conferir('entrega encerra os alertas', '0', TO_CHAR(contar(
        q'[SELECT COUNT(*) FROM T_SH_ALERTA WHERE ID_PEDIDO = 2 AND ST_ALERTA = 'ABERTO']')));
    conferir('encerramento automatico fica auditado', '3', TO_CHAR(contar(
        q'[SELECT COUNT(*) FROM T_SH_ALERTA_AUDITORIA WHERE ID_PEDIDO = 2 AND DS_OPERACAO = 'UPDATE' AND ST_NOVO = 'RESOLVIDO']')));

    PKG_SH_RISCO.SP_RECALCULAR_RISCO(2, v_score, v_nivel, v_rec, v_msg);
    conferir('pedido entregue nao reabre alerta', '0', TO_CHAR(contar(
        q'[SELECT COUNT(*) FROM T_SH_ALERTA WHERE ID_PEDIDO = 2 AND ST_ALERTA = 'ABERTO']')));

    DELETE FROM T_SH_ALERTA WHERE ID_ALERTA = v_alerta;
    conferir('DELETE fica auditado', '1', TO_CHAR(contar(
        q'[SELECT COUNT(*) FROM T_SH_ALERTA_AUDITORIA WHERE DS_OPERACAO = 'DELETE']')));

    ROLLBACK;

    DBMS_OUTPUT.PUT_LINE('=== RESULTADO: ' || v_ok || ' OK, ' || v_falhas || ' FALHA(S) ===');
    IF v_falhas > 0 THEN
        RAISE_APPLICATION_ERROR(-20999, v_falhas || ' teste(s) PL/SQL falharam.');
    END IF;
END;
/
