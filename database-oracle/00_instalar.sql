-- Instala a camada Oracle do zero, com dados simulados e sem testes.
-- E o script usado no deploy automatizado do pipeline.
-- Rode a partir desta pasta:  @00_instalar.sql
SET SERVEROUTPUT ON SIZE UNLIMITED;
SET DEFINE OFF;
@99_drop_all.sql
@01_ddl_tabelas.sql
@02_dados_simulados.sql
@03_pkg_sh_risco.sql
@04_pkg_sh_iot.sql
@05_pkg_sh_usuario.sql
@06_pkg_sh_consulta.sql
@07_triggers.sql
@98_verificar_objetos.sql
