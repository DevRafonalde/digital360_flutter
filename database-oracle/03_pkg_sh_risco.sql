-- =====================================================================
-- Smart HAS / Digital 360 - Consolidacao
-- Script 03: PKG_SH_RISCO - motor de risco da AI Logistics Extension
-- ---------------------------------------------------------------------
--  FN_NIVEL_RISCO      -> classifica um score (0-100) em nivel
--  FN_CALCULA_RISCO    -> INDICADOR: score de risco de atraso
--  FN_RESUMO_PEDIDO    -> DADOS FORMATADOS: resumo do pedido
--  SP_RECALCULAR_RISCO -> recalcula, grava historico e abre alerta.
--                         ACIONADA PELA API JAVA (REST -> JDBC -> Oracle)
--  V_SH_PEDIDO_RISCO   -> view usada pela API e pelo PKG_SH_CONSULTA
--
-- Codigos de erro: -20001 pedido nao encontrado | -20002 parametro
-- invalido | -20011 falha inesperada.
-- Transacao: nada aqui executa COMMIT; quem chama decide.
-- =====================================================================
CREATE OR REPLACE PACKAGE PKG_SH_RISCO AS

    -- Converte o score em nivel (regra identica a do app Flutter):
    -- >= 75 CRITICO | >= 50 ALTO | >= 25 MEDIO | < 25 BAIXO.
    -- DETERMINISTIC: pode ser usada em SELECT, WHERE e ORDER BY.
    FUNCTION FN_NIVEL_RISCO (
        p_score IN NUMBER
    ) RETURN VARCHAR2 DETERMINISTIC;

    -- Score de risco de atraso (0 a 100). Pesos:
    --   +18 por atraso no historico | +12 por reagendamento
    --   +25 sem estoque | +15 se > 20 km | +8 se > 10 km | +20 se ATRASADO
    FUNCTION FN_CALCULA_RISCO (
        p_id_pedido IN T_SH_PEDIDO.ID_PEDIDO%TYPE
    ) RETURN NUMBER;

    -- Linha pronta para exibicao (app, painel ou notificacao).
    FUNCTION FN_RESUMO_PEDIDO (
        p_id_pedido IN T_SH_PEDIDO.ID_PEDIDO%TYPE
    ) RETURN VARCHAR2;

    -- Recalcula o risco, grava T_SH_RISCO_HIST e, se ALTO/CRITICO, abre um
    -- alerta de risco (sem duplicar alerta aberto e nunca para pedido ja
    -- ENTREGUE). Os OUT espelham o contrato RiscoLogistico do app Flutter.
    PROCEDURE SP_RECALCULAR_RISCO (
        p_id_pedido        IN  T_SH_PEDIDO.ID_PEDIDO%TYPE,
        p_score            OUT NUMBER,
        p_nivel            OUT VARCHAR2,
        p_recomendacao     OUT VARCHAR2,
        p_mensagem_cliente OUT VARCHAR2
    );

END PKG_SH_RISCO;
/

CREATE OR REPLACE PACKAGE BODY PKG_SH_RISCO AS

    FUNCTION FN_NIVEL_RISCO (
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

    FUNCTION FN_CALCULA_RISCO (
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

    FUNCTION FN_RESUMO_PEDIDO (
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

    PROCEDURE SP_RECALCULAR_RISCO (
        p_id_pedido        IN  T_SH_PEDIDO.ID_PEDIDO%TYPE,
        p_score            OUT NUMBER,
        p_nivel            OUT VARCHAR2,
        p_recomendacao     OUT VARCHAR2,
        p_mensagem_cliente OUT VARCHAR2
    )
    IS
        v_alertas_abertos NUMBER;
        v_codigo          T_SH_PEDIDO.CD_PEDIDO%TYPE;
        v_status          T_SH_PEDIDO.ST_PEDIDO%TYPE;
    BEGIN
        IF p_id_pedido IS NULL THEN
            RAISE_APPLICATION_ERROR(-20002, 'SP_RECALCULAR_RISCO: o parametro p_id_pedido nao pode ser nulo.');
        END IF;

        -- Reaproveita as functions (levanta -20001 se o pedido nao existir)
        p_score := FN_CALCULA_RISCO(p_id_pedido);
        p_nivel := FN_NIVEL_RISCO(p_score);

        IF p_nivel = 'CRITICO' THEN
            p_recomendacao := 'Acionar suporte logistico e oferecer reagendamento proativo.';
        ELSIF p_nivel = 'ALTO' THEN
            p_recomendacao := 'Monitorar de perto e comunicar o cliente sobre possivel atraso.';
        ELSIF p_nivel = 'MEDIO' THEN
            p_recomendacao := 'Acompanhar a entrega no proximo ciclo de atualizacao.';
        ELSE
            p_recomendacao := 'Entrega dentro do esperado. Nenhuma acao necessaria.';
        END IF;

        IF p_score >= 50 THEN
            p_mensagem_cliente := 'Detectamos fatores que podem afetar a janela prometida.';
        ELSE
            p_mensagem_cliente := 'Sua entrega esta dentro do prazo previsto.';
        END IF;

        -- Auditoria: todo recalculo fica registrado
        INSERT INTO T_SH_RISCO_HIST (ID_RISCO, ID_PEDIDO, NR_SCORE, DS_NIVEL, DS_RECOMENDACAO, DT_CALCULO)
        VALUES (SEQ_SH_RISCO.NEXTVAL, p_id_pedido, p_score, p_nivel, p_recomendacao, SYSTIMESTAMP);

        -- Gestao por excecao: so abre alerta para ALTO/CRITICO, sem duplicar
        -- e sem reabrir o que TRG_SH_PEDIDO_ENTREGUE ja encerrou.
        IF p_nivel IN ('ALTO', 'CRITICO') THEN
            SELECT COUNT(*)
              INTO v_alertas_abertos
              FROM T_SH_ALERTA
             WHERE ID_PEDIDO = p_id_pedido
               AND DS_ORIGEM = 'RISCO'
               AND ST_ALERTA = 'ABERTO';

            SELECT CD_PEDIDO, ST_PEDIDO
              INTO v_codigo, v_status
              FROM T_SH_PEDIDO
             WHERE ID_PEDIDO = p_id_pedido;

            IF v_alertas_abertos = 0 AND v_status <> 'ENTREGUE' THEN
                INSERT INTO T_SH_ALERTA (ID_ALERTA, ID_PEDIDO, ID_LEITURA, DS_ORIGEM, DS_NIVEL, DS_MENSAGEM, DT_ALERTA, ST_ALERTA)
                VALUES (SEQ_SH_ALERTA.NEXTVAL, p_id_pedido, NULL, 'RISCO', p_nivel,
                        'Risco ' || p_nivel || ' (score ' || p_score || ') no pedido ' || v_codigo || ': ' || p_recomendacao,
                        SYSTIMESTAMP, 'ABERTO');
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE BETWEEN -20999 AND -20000 THEN
                RAISE;
            END IF;
            RAISE_APPLICATION_ERROR(-20011, 'SP_RECALCULAR_RISCO: falha inesperada - ' || SQLERRM);
    END SP_RECALCULAR_RISCO;

END PKG_SH_RISCO;
/

-- ---------------------------------------------------------------------
-- View de apoio: integra as functions a uma consulta reutilizavel.
-- Consumida pela API Java e pela busca dinamica do PKG_SH_CONSULTA.
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
       PKG_SH_RISCO.FN_CALCULA_RISCO(p.ID_PEDIDO)                              AS NR_SCORE_RISCO,
       PKG_SH_RISCO.FN_NIVEL_RISCO(PKG_SH_RISCO.FN_CALCULA_RISCO(p.ID_PEDIDO)) AS DS_NIVEL_RISCO,
       PKG_SH_RISCO.FN_RESUMO_PEDIDO(p.ID_PEDIDO)                              AS DS_RESUMO
  FROM T_SH_PEDIDO p;
