-- =====================================================================
-- Smart HAS / Digital 360 - Fase 6
-- Script 04: Procedures PL/SQL
-- ---------------------------------------------------------------------
--  SP_REGISTRAR_ALERTAS_SENSORES -> varre leituras pendentes (CURSOR FOR
--                                   UPDATE + LOOP) e registra alertas
--  SP_RECALCULAR_RISCO           -> recalcula o risco de um pedido, grava
--                                   historico e abre alerta. ACIONADA PELA
--                                   API JAVA (REST -> Java -> JDBC -> Oracle)
--  SP_GERAR_RELATORIO_USUARIOS   -> relatorio resumido por usuario
--                                   (cursor explicito OPEN/FETCH/CLOSE)
--
-- Transacao: as procedures NAO executam COMMIT. Quem chama decide
-- (bloco de teste no script 05 ou a API Java, que usa autocommit).
-- Codigos de erro: -20001 pedido nao encontrado | -20002 parametro
-- invalido | -20003 usuario nao encontrado | -2001x falha inesperada.
-- =====================================================================

-- ---------------------------------------------------------------------
-- SP_REGISTRAR_ALERTAS_SENSORES
-- Proposito: rotina automatizada de monitoramento IoT. Percorre as
-- leituras ainda nao processadas, compara com a faixa segura do sensor
-- e grava um alerta para cada leitura fora da faixa.
-- Classificacao:
--   fora da faixa ate 20% da amplitude do sensor -> ALTO
--   fora da faixa acima de 20% da amplitude      -> CRITICO
-- Parametros:
--   p_id_pedido  IN  (opcional) restringe a um pedido; NULL = todos
--   p_qt_alertas OUT quantidade de alertas gerados nesta execucao
-- Conceitos: CURSOR com FOR UPDATE, LOOP, IF/ELSIF, WHERE CURRENT OF,
--            funcao local, EXCEPTION.
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE SP_REGISTRAR_ALERTAS_SENSORES (
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

    -- Funcao local: formata numero com ponto decimal, independente do NLS
    FUNCTION fmt (p_valor IN NUMBER) RETURN VARCHAR2 IS
    BEGIN
        RETURN TO_CHAR(p_valor, 'FM99990.00', 'NLS_NUMERIC_CHARACTERS=''.,''');
    END fmt;
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
/

-- ---------------------------------------------------------------------
-- SP_RECALCULAR_RISCO   (acionada pelo back-end Java via JDBC)
-- Proposito: e o "motor de risco" da AI Logistics Extension dentro do
-- banco. Calcula o score com FN_CALCULA_RISCO, classifica com
-- FN_NIVEL_RISCO, grava o historico e, se o nivel for ALTO ou CRITICO,
-- abre um alerta de risco (sem duplicar alerta ja aberto).
-- Parametros:
--   p_id_pedido        IN   pedido a recalcular
--   p_score            OUT  score 0-100
--   p_nivel            OUT  BAIXO | MEDIO | ALTO | CRITICO
--   p_recomendacao     OUT  acao recomendada para a operacao
--   p_mensagem_cliente OUT  texto amigavel para o cliente (app)
-- Os OUT espelham o contrato RiscoLogistico ja usado pelo app Flutter.
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE SP_RECALCULAR_RISCO (
    p_id_pedido        IN  T_SH_PEDIDO.ID_PEDIDO%TYPE,
    p_score            OUT NUMBER,
    p_nivel            OUT VARCHAR2,
    p_recomendacao     OUT VARCHAR2,
    p_mensagem_cliente OUT VARCHAR2
)
IS
    v_alertas_abertos NUMBER;
    v_codigo          T_SH_PEDIDO.CD_PEDIDO%TYPE;
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

    -- Gestao por excecao: so abre alerta para ALTO/CRITICO e sem duplicar
    IF p_nivel IN ('ALTO', 'CRITICO') THEN
        SELECT COUNT(*)
          INTO v_alertas_abertos
          FROM T_SH_ALERTA
         WHERE ID_PEDIDO = p_id_pedido
           AND DS_ORIGEM = 'RISCO'
           AND ST_ALERTA = 'ABERTO';

        IF v_alertas_abertos = 0 THEN
            SELECT CD_PEDIDO INTO v_codigo FROM T_SH_PEDIDO WHERE ID_PEDIDO = p_id_pedido;

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
/

-- ---------------------------------------------------------------------
-- SP_GERAR_RELATORIO_USUARIOS
-- Proposito: gerar o relatorio resumido de consumo/engajamento por
-- usuario (trilhas, progresso medio, pedidos e alertas em aberto),
-- gravando um snapshot em T_SH_RELATORIO_USUARIO e imprimindo um
-- resumo via DBMS_OUTPUT.
-- Classificacao: progresso medio >= 70 ENGAJADO | >= 30 EM_PROGRESSO |
--                abaixo disso INICIANTE
-- Parametros:
--   p_id_usuario IN (opcional) gera para um usuario; NULL = todos
--   p_qt_linhas  OUT quantidade de usuarios processados
-- Conceitos: cursor explicito com parametro, LOOP com EXIT WHEN
--            %NOTFOUND, %ISOPEN, IF/ELSIF, EXCEPTION.
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE SP_GERAR_RELATORIO_USUARIOS (
    p_id_usuario IN  T_SH_USUARIO.ID_USUARIO%TYPE DEFAULT NULL,
    p_qt_linhas  OUT NUMBER
)
IS
    CURSOR c_usuarios (cp_id_usuario NUMBER) IS
        SELECT u.ID_USUARIO, u.NM_USUARIO, u.DS_PERFIL
          FROM T_SH_USUARIO u
         WHERE cp_id_usuario IS NULL OR u.ID_USUARIO = cp_id_usuario
         ORDER BY u.ID_USUARIO;

    r_usuario         c_usuarios%ROWTYPE;
    v_existe          NUMBER;
    v_qt_cursos       NUMBER;
    v_progresso       NUMBER;
    v_qt_pedidos      NUMBER;
    v_qt_alertas      NUMBER;
    v_classificacao   T_SH_RELATORIO_USUARIO.DS_CLASSIFICACAO%TYPE;
BEGIN
    p_qt_linhas := 0;

    IF p_id_usuario IS NOT NULL THEN
        SELECT COUNT(*) INTO v_existe FROM T_SH_USUARIO WHERE ID_USUARIO = p_id_usuario;
        IF v_existe = 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'SP_GERAR_RELATORIO_USUARIOS: usuario nao encontrado (ID ' || p_id_usuario || ').');
        END IF;
    END IF;

    DBMS_OUTPUT.PUT_LINE('=== Relatorio resumido por usuario - Smart HAS / Digital 360 ===');
    DBMS_OUTPUT.PUT_LINE(RPAD('ID', 4) || RPAD('USUARIO', 24) || RPAD('CURSOS', 8) || RPAD('PROGR.', 8)
                         || RPAD('PEDIDOS', 9) || RPAD('ALERTAS', 9) || 'CLASSIFICACAO');

    OPEN c_usuarios(p_id_usuario);
    LOOP
        FETCH c_usuarios INTO r_usuario;
        EXIT WHEN c_usuarios%NOTFOUND;

        SELECT COUNT(*) INTO v_qt_cursos
          FROM T_SH_MATRICULA
         WHERE ID_USUARIO = r_usuario.ID_USUARIO;

        v_progresso := FN_PROGRESSO_MEDIO_USUARIO(r_usuario.ID_USUARIO);

        SELECT COUNT(*) INTO v_qt_pedidos
          FROM T_SH_PEDIDO
         WHERE ID_USUARIO = r_usuario.ID_USUARIO;

        SELECT COUNT(*) INTO v_qt_alertas
          FROM T_SH_ALERTA a
          JOIN T_SH_PEDIDO p ON p.ID_PEDIDO = a.ID_PEDIDO
         WHERE p.ID_USUARIO = r_usuario.ID_USUARIO
           AND a.ST_ALERTA = 'ABERTO';

        IF v_progresso >= 70 THEN
            v_classificacao := 'ENGAJADO';
        ELSIF v_progresso >= 30 THEN
            v_classificacao := 'EM_PROGRESSO';
        ELSE
            v_classificacao := 'INICIANTE';
        END IF;

        INSERT INTO T_SH_RELATORIO_USUARIO (ID_RELATORIO, ID_USUARIO, DT_GERACAO, QT_CURSOS, VL_PROGRESSO_MEDIO,
                                            QT_PEDIDOS, QT_ALERTAS_ABERTOS, DS_CLASSIFICACAO)
        VALUES (SEQ_SH_RELATORIO.NEXTVAL, r_usuario.ID_USUARIO, SYSTIMESTAMP, v_qt_cursos, v_progresso,
                v_qt_pedidos, v_qt_alertas, v_classificacao);

        DBMS_OUTPUT.PUT_LINE(RPAD(r_usuario.ID_USUARIO, 4) || RPAD(SUBSTR(r_usuario.NM_USUARIO, 1, 23), 24)
                             || RPAD(v_qt_cursos, 8) || RPAD(v_progresso, 8) || RPAD(v_qt_pedidos, 9)
                             || RPAD(v_qt_alertas, 9) || v_classificacao);

        p_qt_linhas := p_qt_linhas + 1;
    END LOOP;
    CLOSE c_usuarios;

    DBMS_OUTPUT.PUT_LINE('Usuarios processados: ' || p_qt_linhas);
EXCEPTION
    WHEN OTHERS THEN
        IF c_usuarios%ISOPEN THEN
            CLOSE c_usuarios;
        END IF;
        IF SQLCODE BETWEEN -20999 AND -20000 THEN
            RAISE;
        END IF;
        RAISE_APPLICATION_ERROR(-20012, 'SP_GERAR_RELATORIO_USUARIOS: falha inesperada - ' || SQLERRM);
END SP_GERAR_RELATORIO_USUARIOS;
/
