package com.smarthas.backend.plsql.dto;

/** Corpo do POST /sensores/{id}/leituras enviado pelo gateway IoT. */
public record OracleLeituraRequest(Double valor) {
}
