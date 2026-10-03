package com.smarthas.backend.plsql.dto;

/** Linha do relatorio gerado por SP_GERAR_RELATORIO_USUARIOS. */
public record OracleRelatorioUsuario(
        long usuarioId,
        String nome,
        int cursos,
        double progressoMedio,
        int pedidos,
        int alertasAbertos,
        String classificacao,
        String geradoEm
) {
}
