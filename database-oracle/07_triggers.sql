-- =====================================================================
-- Smart HAS / Digital 360 - Consolidacao
-- Script 07: Triggers de auditoria e automacao
-- ---------------------------------------------------------------------
--  TRG_SH_ALERTA_AUDITORIA -> registra toda mudanca em T_SH_ALERTA
--  TRG_SH_PEDIDO_ENTREGUE  -> encerra os alertas quando o pedido e entregue
--
-- As duas se complementam: o encerramento automatico tambem aparece na
-- auditoria, porque o UPDATE da segunda dispara a primeira.
-- =====================================================================

-- ---------------------------------------------------------------------
-- TRG_SH_ALERTA_AUDITORIA  (auditoria)
-- Grava quem, quando e de onde cada alerta foi criado, mudou de status
-- ou foi removido, sem depender de a aplicacao lembrar de registrar. Vale
-- para API, SQL Developer ou qualquer outro cliente.
-- A linha de auditoria participa da transacao do alerta: se a alteracao
-- sofrer ROLLBACK, o registro desaparece junto.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_SH_ALERTA_AUDITORIA
AFTER INSERT OR DELETE OR UPDATE OF ST_ALERTA ON T_SH_ALERTA
FOR EACH ROW
DECLARE
    v_operacao T_SH_ALERTA_AUDITORIA.DS_OPERACAO%TYPE;
BEGIN
    v_operacao := CASE
                      WHEN INSERTING THEN 'INSERT'
                      WHEN UPDATING  THEN 'UPDATE'
                      ELSE 'DELETE'
                  END;

    INSERT INTO T_SH_ALERTA_AUDITORIA (ID_AUDITORIA, ID_ALERTA, ID_PEDIDO, DS_OPERACAO, ST_ANTERIOR, ST_NOVO,
                                       DS_NIVEL, NM_USUARIO_BD, NM_MODULO, DT_EVENTO)
    VALUES (SEQ_SH_AUDITORIA.NEXTVAL,
            COALESCE(:NEW.ID_ALERTA, :OLD.ID_ALERTA),
            COALESCE(:NEW.ID_PEDIDO, :OLD.ID_PEDIDO),
            v_operacao,
            :OLD.ST_ALERTA,
            :NEW.ST_ALERTA,
            COALESCE(:NEW.DS_NIVEL, :OLD.DS_NIVEL),
            USER,
            SUBSTR(SYS_CONTEXT('USERENV', 'MODULE'), 1, 48),
            SYSTIMESTAMP);
END TRG_SH_ALERTA_AUDITORIA;
/

-- ---------------------------------------------------------------------
-- TRG_SH_PEDIDO_ENTREGUE  (automacao)
-- Quando o pedido passa para ENTREGUE, nao ha mais o que acompanhar: os
-- alertas abertos sao encerrados na hora, e o operador so ve o que ainda
-- exige acao. Dispara apenas na transicao de status.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_SH_PEDIDO_ENTREGUE
AFTER UPDATE OF ST_PEDIDO ON T_SH_PEDIDO
FOR EACH ROW
WHEN (NEW.ST_PEDIDO = 'ENTREGUE' AND OLD.ST_PEDIDO <> 'ENTREGUE')
BEGIN
    UPDATE T_SH_ALERTA
       SET ST_ALERTA = 'RESOLVIDO'
     WHERE ID_PEDIDO = :NEW.ID_PEDIDO
       AND ST_ALERTA = 'ABERTO';
END TRG_SH_PEDIDO_ENTREGUE;
/
