package com.smarthas.backend.dto;

/** Espelha {"status": "...", "total<Algo>": N} devolvido por varios endpoints do backend Python. */
public record StatusContagemResponse(String status, Long total) {
}
