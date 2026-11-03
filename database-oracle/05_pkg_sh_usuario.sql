-- =====================================================================
-- Smart HAS / Digital 360 - Consolidacao
-- Script 05: PKG_SH_USUARIO - engajamento dos usuarios nas trilhas
-- ---------------------------------------------------------------------
--  FN_PROGRESSO_MEDIO_USUARIO  -> INDICADOR: progresso medio nas trilhas
--  SP_GERAR_RELATORIO_USUARIOS -> relatorio resumido por usuario
--                                 (cursor explicito OPEN/FETCH/CLOSE)
-- Codigos de erro: -20002 parametro invalido | -20003 usuario nao
-- encontrado | -20012 falha inesperada.
-- =====================================================================
CREATE OR REPLACE PACKAGE PKG_SH_USUARIO AS

    -- Media do progresso (0-100) do usuario nas trilhas em que esta
    -- matriculado. Retorna 0 quando o usuario nao tem matriculas.
    FUNCTION FN_PROGRESSO_MEDIO_USUARIO (
        p_id_usuario IN T_SH_USUARIO.ID_USUARIO%TYPE
    ) RETURN NUMBER;

    -- Grava um snapshot por usuario em T_SH_RELATORIO_USUARIO e imprime o
    -- resumo via DBMS_OUTPUT. Classificacao pelo progresso medio:
    -- >= 70 ENGAJADO | >= 30 EM_PROGRESSO | abaixo disso INICIANTE.
    --   p_id_usuario IN  (opcional) um usuario; NULL = todos
    --   p_qt_linhas  OUT quantidade de usuarios processados
    PROCEDURE SP_GERAR_RELATORIO_USUARIOS (
        p_id_usuario IN  T_SH_USUARIO.ID_USUARIO%TYPE DEFAULT NULL,
        p_qt_linhas  OUT NUMBER
    );

END PKG_SH_USUARIO;
/

CREATE OR REPLACE PACKAGE BODY PKG_SH_USUARIO AS

    FUNCTION FN_PROGRESSO_MEDIO_USUARIO (
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

    PROCEDURE SP_GERAR_RELATORIO_USUARIOS (
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

END PKG_SH_USUARIO;
/
