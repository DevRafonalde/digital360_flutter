-- Executa toda a camada Oracle em ordem (SQL*Plus / SQLcl / SQL Developer F5)
-- Rode a partir desta pasta:  @00_executar_tudo.sql
SET SERVEROUTPUT ON SIZE UNLIMITED;
SET DEFINE OFF;
@99_drop_all.sql
@01_ddl_tabelas.sql
@02_dados_simulados.sql
@03_functions.sql
@04_procedures.sql
@05_testes_e_consultas.sql
