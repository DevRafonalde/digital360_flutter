-- =====================================================================
-- Script 98: falha se algum objeto ficou invalido
-- Erro de compilacao em package ou trigger nao interrompe o SQL*Plus (so
-- mostra um aviso). Este bloco transforma esse aviso em erro de verdade,
-- para que o pipeline nao faca deploy de um banco quebrado.
-- =====================================================================
DECLARE
    v_invalidos VARCHAR2(4000);
BEGIN
    DBMS_UTILITY.COMPILE_SCHEMA(schema => USER, compile_all => FALSE);

    SELECT LISTAGG(OBJECT_TYPE || ' ' || OBJECT_NAME, ', ') WITHIN GROUP (ORDER BY OBJECT_NAME)
      INTO v_invalidos
      FROM USER_OBJECTS
     WHERE STATUS <> 'VALID';

    IF v_invalidos IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20998, 'Objetos invalidos: ' || v_invalidos);
    END IF;

    DBMS_OUTPUT.PUT_LINE('Verificacao concluida: todos os objetos estao VALID.');
END;
/
