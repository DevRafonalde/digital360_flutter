package com.smarthas.backend.plsql.dto;

/** Linha de T_SH_ALERTA_AUDITORIA, preenchida pela trigger TRG_SH_ALERTA_AUDITORIA. */
public record OracleAuditoriaAlerta(
        long id,
        long alertaId,
        long pedidoId,
        String operacao,
        String statusAnterior,
        String statusNovo,
        String nivel,
        String usuarioBanco,
        String modulo,
        String dataHora
) {
}
