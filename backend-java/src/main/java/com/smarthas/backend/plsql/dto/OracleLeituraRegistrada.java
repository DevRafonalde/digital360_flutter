package com.smarthas.backend.plsql.dto;

/** Resposta do registro de leitura: id gerado e alertas abertos pela procedure. */
public record OracleLeituraRegistrada(long leituraId, long sensorId, long pedidoId, double valor, int alertasGerados) {
}
