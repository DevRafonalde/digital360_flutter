package com.smarthas.backend.service;

/** Item de referencia do motor de recomendacao/tendencias. Espelha data.py::CATALOGO. */
public record CatalogoItem(String tipo, Long id, String titulo, String nivel, String categoria) {
}
