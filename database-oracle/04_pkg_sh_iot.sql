-- =====================================================================
-- Smart HAS / Digital 360 - Consolidacao
-- Script 04: PKG_SH_IOT - monitoramento de sensores e ciclo do alerta
-- ---------------------------------------------------------------------
--  SP_REGISTRAR_ALERTAS_SENSORES -> varre leituras pendentes (CURSOR FOR
--                                   UPDATE + LOOP) e registra alertas
--  SP_RESOLVER_ALERTA            -> encerra um alerta aberto (a mudanca
--                                   fica na auditoria via trigger)
--
-- Codigos de erro: -20001 pedido nao encontrado | -20002 parametro
-- invalido | -20004 alerta nao encontrado | -20010 falha inesperada.
-- Transacao: nada aqui executa COMMIT; quem chama decide.
-- =====================================================================
CREATE OR REPLACE PACKAGE PKG_SH_IOT AS

    -- Percorre as leituras nao processadas, compara com a faixa segura do
    -- sensor e grava um alerta para cada leitura fora da faixa.
    --   fora da faixa ate 20% da amplitude do sensor -> ALTO
    --   fora da faixa acima de 20% da amplitude      -> CRITICO
    --   p_id_pedido  IN  (opcional) restringe a um pedido; NULL = todos
    --   p_qt_alertas OUT quantidade de alertas gerados nesta execucao
    PROCEDURE SP_REGISTRAR_ALERTAS_SENSORES (
        p_id_pedido  IN  T_SH_PEDIDO.ID_PEDIDO%TYPE DEFAULT NULL,
        p_qt_alertas OUT NUMBER
    );

    -- Marca o alerta como RESOLVIDO. Idempotente: resolver de novo um
    -- alerta ja resolvido nao altera nada nem gera linha de auditoria.
    PROCEDURE SP_RESOLVER_ALERTA (
        p_id_alerta IN T_SH_ALERTA.ID_ALERTA%TYPE
    );

END PKG_SH_IOT;
/

CREATE OR REPLACE PACKAGE BODY PKG_SH_IOT AS

    -- Privada: formata numero com ponto decimal, independente do NLS
    FUNCTION fmt (p_valor IN NUMBER) RETURN VARCHAR2 IS
    BEGIN
        RETURN TO_CHAR(p_valor, 'FM99990.00', 'NLS_NUMERIC_CHARACTERS=''.,''');
    END fmt;

    PROCEDURE SP_REGISTRAR_ALERTAS_SENSORES (
        p_id_pedido  IN  T_SH_PEDIDO.ID_PEDIDO%TYPE DEFAULT NULL,
        p_qt_alertas OUT NUMBER
    )
    IS
        CURSOR c_leituras IS
            SELECT l.ID_LEITURA,
                   l.VL_LEITURA,
                   s.ID_PEDIDO,
                   s.DS_TIPO,
                   s.DS_UNIDADE,
                   s.VL_LIMITE_MIN,
                   s.VL_LIMITE_MAX,
                   p.CD_PEDIDO
              FROM T_SH_LEITURA l
              JOIN T_SH_SENSOR  s ON s.ID_SENSOR = l.ID_SENSOR
              JOIN T_SH_PEDIDO  p ON p.ID_PEDIDO = s.ID_PEDIDO
             WHERE l.FL_PROCESSADA = 'N'
               AND (p_id_pedido IS NULL OR s.ID_PEDIDO = p_id_pedido)
             ORDER BY l.DT_LEITURA
               FOR UPDATE OF l.FL_PROCESSADA;

        v_existe     NUMBER;
        v_amplitude  NUMBER;
        v_desvio     NUMBER;
        v_nivel      T_SH_ALERTA.DS_NIVEL%TYPE;
        v_mensagem   T_SH_ALERTA.DS_MENSAGEM%TYPE;
    BEGIN
        p_qt_alertas := 0;

        IF p_id_pedido IS NOT NULL THEN
            SELECT COUNT(*) INTO v_existe FROM T_SH_PEDIDO WHERE ID_PEDIDO = p_id_pedido;
            IF v_existe = 0 THEN
                RAISE_APPLICATION_ERROR(-20001, 'SP_REGISTRAR_ALERTAS_SENSORES: pedido nao encontrado (ID ' || p_id_pedido || ').');
            END IF;
        END IF;

        FOR r IN c_leituras LOOP
            v_desvio := 0;
            IF r.VL_LEITURA > r.VL_LIMITE_MAX THEN
                v_desvio := r.VL_LEITURA - r.VL_LIMITE_MAX;
            ELSIF r.VL_LEITURA < r.VL_LIMITE_MIN THEN
                v_desvio := r.VL_LIMITE_MIN - r.VL_LEITURA;
            END IF;

            IF v_desvio > 0 THEN
                v_amplitude := r.VL_LIMITE_MAX - r.VL_LIMITE_MIN;

                IF v_desvio > v_amplitude * 0.20 THEN
                    v_nivel := 'CRITICO';
                ELSE
                    v_nivel := 'ALTO';
                END IF;

                v_mensagem := 'Sensor de ' || r.DS_TIPO || ' do pedido ' || r.CD_PEDIDO
                           || ' fora da faixa segura: ' || fmt(r.VL_LEITURA) || ' ' || r.DS_UNIDADE
                           || ' (faixa ' || fmt(r.VL_LIMITE_MIN) || ' a ' || fmt(r.VL_LIMITE_MAX) || ' ' || r.DS_UNIDADE || ')';

                INSERT INTO T_SH_ALERTA (ID_ALERTA, ID_PEDIDO, ID_LEITURA, DS_ORIGEM, DS_NIVEL, DS_MENSAGEM, DT_ALERTA, ST_ALERTA)
                VALUES (SEQ_SH_ALERTA.NEXTVAL, r.ID_PEDIDO, r.ID_LEITURA, 'SENSOR', v_nivel, v_mensagem, SYSTIMESTAMP, 'ABERTO');

                p_qt_alertas := p_qt_alertas + 1;
            END IF;

            -- Marca a leitura como processada (com ou sem alerta)
            UPDATE T_SH_LEITURA
               SET FL_PROCESSADA = 'S'
             WHERE CURRENT OF c_leituras;
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE BETWEEN -20999 AND -20000 THEN
                RAISE;   -- erro de negocio ja padronizado: propaga como esta
            END IF;
            RAISE_APPLICATION_ERROR(-20010, 'SP_REGISTRAR_ALERTAS_SENSORES: falha inesperada - ' || SQLERRM);
    END SP_REGISTRAR_ALERTAS_SENSORES;

    PROCEDURE SP_RESOLVER_ALERTA (
        p_id_alerta IN T_SH_ALERTA.ID_ALERTA%TYPE
    )
    IS
        v_existe NUMBER;
    BEGIN
        IF p_id_alerta IS NULL THEN
            RAISE_APPLICATION_ERROR(-20002, 'SP_RESOLVER_ALERTA: o parametro p_id_alerta nao pode ser nulo.');
        END IF;

        SELECT COUNT(*) INTO v_existe FROM T_SH_ALERTA WHERE ID_ALERTA = p_id_alerta;
        IF v_existe = 0 THEN
            RAISE_APPLICATION_ERROR(-20004, 'SP_RESOLVER_ALERTA: alerta nao encontrado (ID ' || p_id_alerta || ').');
        END IF;

        UPDATE T_SH_ALERTA
           SET ST_ALERTA = 'RESOLVIDO'
         WHERE ID_ALERTA = p_id_alerta
           AND ST_ALERTA = 'ABERTO';
    END SP_RESOLVER_ALERTA;

END PKG_SH_IOT;
/
