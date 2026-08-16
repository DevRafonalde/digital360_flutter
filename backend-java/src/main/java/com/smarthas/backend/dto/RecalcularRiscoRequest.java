package com.smarthas.backend.dto;

/** impactoClima (0-25): quanto o clima real da regiao pesa no score, conforme app Flutter. */
public record RecalcularRiscoRequest(Integer impactoClima) {
}
