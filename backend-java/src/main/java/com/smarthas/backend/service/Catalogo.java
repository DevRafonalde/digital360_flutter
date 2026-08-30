package com.smarthas.backend.service;

import java.util.List;

/**
 * Lista estatica de referencia (titulo/nivel/categoria) usada pelo motor de
 * recomendacao para pontuar o catalogo, sem precisar fazer join com o banco
 * de cursos/servicos reais. Espelha data.py::CATALOGO 1-para-1.
 */
public final class Catalogo {

    private Catalogo() {}

    public static final List<CatalogoItem> ITENS = List.of(
            new CatalogoItem("curso", 1L, "Primeiros passos no celular", "BASICO", null),
            new CatalogoItem("curso", 2L, "Usando o gov.br", "INTERMEDIARIO", null),
            new CatalogoItem("curso", 3L, "Seguranca digital e golpes", "INTERMEDIARIO", null),
            new CatalogoItem("curso", 4L, "Pix e pagamentos digitais", "AVANCADO", null),
            new CatalogoItem("servico", 1L, "Consultar beneficio do INSS", null, "Previdencia"),
            new CatalogoItem("servico", 2L, "Agendar consulta no SUS", null, "Saude"),
            new CatalogoItem("servico", 3L, "Emitir 2a via do RG/CPF", null, "Documentos"),
            new CatalogoItem("servico", 4L, "Consultar Bolsa Familia", null, "Assistencia Social")
    );
}
