package com.smarthas.backend.plsql.dto;

/** Indicadores agrupados por PKG_SH_CONSULTA.FN_RESUMO_POR_DIMENSAO. */
public record OracleResumoPedidos(
        String grupo,
        int quantidade,
        double scoreMedio,
        int emRisco
) {
}
