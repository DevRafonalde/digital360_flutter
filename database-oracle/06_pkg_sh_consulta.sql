-- =====================================================================
-- Smart HAS / Digital 360 - Consolidacao
-- Script 06: PKG_SH_CONSULTA - consultas em tempo real com Dynamic SQL
-- ---------------------------------------------------------------------
--  FN_BUSCAR_PEDIDOS      -> DBMS_SQL: o numero de filtros varia a cada
--                            chamada, entao os binds tambem variam
--  FN_RESUMO_POR_DIMENSAO -> SQL dinamico nativo (OPEN FOR): a coluna de
--                            agrupamento so e conhecida em execucao
--
-- Por que nao SQL estatico: o operador do painel combina filtros, ordem e
-- agrupamento livremente. Um SELECT fixo exigiria uma consulta para cada
-- combinacao, ou um "(:p IS NULL OR col = :p)" que atrapalha o otimizador.
--
-- Protecao contra SQL Injection:
--   * valores do usuario entram SEMPRE como bind variable;
--   * nomes de coluna e direcao nunca vem do chamador: ele informa um
--     apelido (score, prazo, status...) que o pacote traduz por lista
--     fechada. Apelido desconhecido gera -20002.
-- =====================================================================
CREATE OR REPLACE PACKAGE PKG_SH_CONSULTA AS

    -- Busca pedidos em V_SH_PEDIDO_RISCO. Todo filtro e opcional (NULL =
    -- nao filtra).
    --   p_status      PENDENTE | EM_TRANSITO | ENTREGUE | ATRASADO
    --   p_nivel_risco BAIXO | MEDIO | ALTO | CRITICO
    --   p_regiao      trecho da regiao de entrega (sem diferenciar caixa)
    --   p_score_min   score minimo, de 0 a 100
    --   p_ordenar_por score | prazo | distancia | codigo | status
    --   p_direcao     ASC | DESC
    FUNCTION FN_BUSCAR_PEDIDOS (
        p_status      IN VARCHAR2 DEFAULT NULL,
        p_nivel_risco IN VARCHAR2 DEFAULT NULL,
        p_regiao      IN VARCHAR2 DEFAULT NULL,
        p_score_min   IN NUMBER   DEFAULT NULL,
        p_ordenar_por IN VARCHAR2 DEFAULT 'score',
        p_direcao     IN VARCHAR2 DEFAULT 'DESC'
    ) RETURN SYS_REFCURSOR;

    -- Indicadores agrupados por: status | nivel | regiao | parceiro.
    -- Colunas: DS_GRUPO, QT_PEDIDOS, VL_SCORE_MEDIO, QT_EM_RISCO.
    FUNCTION FN_RESUMO_POR_DIMENSAO (
        p_dimensao IN VARCHAR2
    ) RETURN SYS_REFCURSOR;

END PKG_SH_CONSULTA;
/

CREATE OR REPLACE PACKAGE BODY PKG_SH_CONSULTA AS

    -- Privada: padroniza o erro de parametro invalido
    PROCEDURE erro_parametro (p_nome IN VARCHAR2, p_valor IN VARCHAR2) IS
    BEGIN
        RAISE_APPLICATION_ERROR(-20002, 'PKG_SH_CONSULTA: valor invalido para ' || p_nome
                                        || ': ' || SUBSTR(p_valor, 1, 40));
    END erro_parametro;

    FUNCTION FN_BUSCAR_PEDIDOS (
        p_status      IN VARCHAR2 DEFAULT NULL,
        p_nivel_risco IN VARCHAR2 DEFAULT NULL,
        p_regiao      IN VARCHAR2 DEFAULT NULL,
        p_score_min   IN NUMBER   DEFAULT NULL,
        p_ordenar_por IN VARCHAR2 DEFAULT 'score',
        p_direcao     IN VARCHAR2 DEFAULT 'DESC'
    ) RETURN SYS_REFCURSOR
    IS
        -- SUBSTR: entrada longa cai na validacao, e nao em estouro de variavel
        v_status  VARCHAR2(40)   := SUBSTR(UPPER(TRIM(p_status)), 1, 40);
        v_nivel   VARCHAR2(40)   := SUBSTR(UPPER(TRIM(p_nivel_risco)), 1, 40);
        v_direcao VARCHAR2(40)   := SUBSTR(UPPER(TRIM(NVL(p_direcao, 'DESC'))), 1, 40);
        v_coluna  VARCHAR2(30);
        v_sql     VARCHAR2(1000) := 'SELECT * FROM V_SH_PEDIDO_RISCO WHERE 1 = 1';
        v_cursor  NUMBER;
        v_linhas  NUMBER;
    BEGIN
        IF v_status IS NOT NULL AND v_status NOT IN ('PENDENTE', 'EM_TRANSITO', 'ENTREGUE', 'ATRASADO') THEN
            erro_parametro('status', p_status);
        END IF;
        IF v_nivel IS NOT NULL AND v_nivel NOT IN ('BAIXO', 'MEDIO', 'ALTO', 'CRITICO') THEN
            erro_parametro('nivel de risco', p_nivel_risco);
        END IF;
        IF p_score_min IS NOT NULL AND (p_score_min < 0 OR p_score_min > 100) THEN
            erro_parametro('score minimo', TO_CHAR(p_score_min));
        END IF;
        IF v_direcao NOT IN ('ASC', 'DESC') THEN
            erro_parametro('direcao', p_direcao);
        END IF;

        v_coluna := CASE LOWER(TRIM(NVL(p_ordenar_por, 'score')))
                        WHEN 'score'     THEN 'NR_SCORE_RISCO'
                        WHEN 'prazo'     THEN 'DT_PRAZO'
                        WHEN 'distancia' THEN 'NR_DISTANCIA_KM'
                        WHEN 'codigo'    THEN 'CD_PEDIDO'
                        WHEN 'status'    THEN 'ST_PEDIDO'
                    END;
        IF v_coluna IS NULL THEN
            erro_parametro('ordenacao', p_ordenar_por);
        END IF;

        -- O texto do SQL so recebe trechos fixos deste pacote
        IF v_status IS NOT NULL THEN
            v_sql := v_sql || ' AND ST_PEDIDO = :status';
        END IF;
        IF v_nivel IS NOT NULL THEN
            v_sql := v_sql || ' AND DS_NIVEL_RISCO = :nivel';
        END IF;
        IF p_regiao IS NOT NULL THEN
            v_sql := v_sql || ' AND UPPER(DS_REGIAO_ENTREGA) LIKE :regiao';
        END IF;
        IF p_score_min IS NOT NULL THEN
            v_sql := v_sql || ' AND NR_SCORE_RISCO >= :score_min';
        END IF;
        v_sql := v_sql || ' ORDER BY ' || v_coluna || ' ' || v_direcao || ', ID_PEDIDO';

        -- DBMS_SQL: necessario porque a quantidade de binds varia
        v_cursor := DBMS_SQL.OPEN_CURSOR;
        DBMS_SQL.PARSE(v_cursor, v_sql, DBMS_SQL.NATIVE);

        IF v_status IS NOT NULL THEN
            DBMS_SQL.BIND_VARIABLE(v_cursor, ':status', v_status);
        END IF;
        IF v_nivel IS NOT NULL THEN
            DBMS_SQL.BIND_VARIABLE(v_cursor, ':nivel', v_nivel);
        END IF;
        IF p_regiao IS NOT NULL THEN
            DBMS_SQL.BIND_VARIABLE(v_cursor, ':regiao', '%' || UPPER(p_regiao) || '%');
        END IF;
        IF p_score_min IS NOT NULL THEN
            DBMS_SQL.BIND_VARIABLE(v_cursor, ':score_min', p_score_min);
        END IF;

        v_linhas := DBMS_SQL.EXECUTE(v_cursor);
        RETURN DBMS_SQL.TO_REFCURSOR(v_cursor);
    EXCEPTION
        WHEN OTHERS THEN
            IF v_cursor IS NOT NULL AND DBMS_SQL.IS_OPEN(v_cursor) THEN
                DBMS_SQL.CLOSE_CURSOR(v_cursor);
            END IF;
            RAISE;
    END FN_BUSCAR_PEDIDOS;

    FUNCTION FN_RESUMO_POR_DIMENSAO (
        p_dimensao IN VARCHAR2
    ) RETURN SYS_REFCURSOR
    IS
        v_coluna VARCHAR2(30);
        v_cursor SYS_REFCURSOR;
    BEGIN
        v_coluna := CASE LOWER(TRIM(p_dimensao))
                        WHEN 'status'   THEN 'ST_PEDIDO'
                        WHEN 'nivel'    THEN 'DS_NIVEL_RISCO'
                        WHEN 'regiao'   THEN 'DS_REGIAO_ENTREGA'
                        WHEN 'parceiro' THEN 'NM_PARCEIRO'
                    END;
        IF v_coluna IS NULL THEN
            erro_parametro('dimensao', p_dimensao);
        END IF;

        -- SQL dinamico nativo: so a coluna muda, e ela vem da lista fechada
        OPEN v_cursor FOR
            'SELECT ' || v_coluna || ' AS DS_GRUPO,'
            || ' COUNT(*) AS QT_PEDIDOS,'
            || ' ROUND(AVG(NR_SCORE_RISCO), 1) AS VL_SCORE_MEDIO,'
            || ' SUM(CASE WHEN DS_NIVEL_RISCO IN (''ALTO'', ''CRITICO'') THEN 1 ELSE 0 END) AS QT_EM_RISCO'
            || ' FROM V_SH_PEDIDO_RISCO'
            || ' GROUP BY ' || v_coluna
            || ' ORDER BY VL_SCORE_MEDIO DESC, DS_GRUPO';

        RETURN v_cursor;
    END FN_RESUMO_POR_DIMENSAO;

END PKG_SH_CONSULTA;
/
