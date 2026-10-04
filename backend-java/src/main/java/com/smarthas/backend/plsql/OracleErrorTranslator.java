package com.smarthas.backend.plsql;

import com.smarthas.backend.exception.ApiException;
import org.springframework.http.HttpStatus;

import java.sql.SQLException;

/**
 * Traduz os erros padronizados das functions/procedures PL/SQL
 * (RAISE_APPLICATION_ERROR) para o {@link ApiException} que o
 * GlobalExceptionHandler do backend ja converte em resposta HTTP.
 *
 *   ORA-20001 pedido nao encontrado  -> 404
 *   ORA-20003 usuario nao encontrado -> 404
 *   ORA-20002 parametro invalido     -> 400
 *   demais (conexao, SQL inesperado) -> 503
 */
public final class OracleErrorTranslator {

    private OracleErrorTranslator() {
    }

    public static ApiException traduzir(String operacao, SQLException e) {
        String mensagem = limpar(e.getMessage());
        return switch (e.getErrorCode()) {
            case 20001, 20003 -> new ApiException(HttpStatus.NOT_FOUND, mensagem);
            case 20002 -> new ApiException(HttpStatus.BAD_REQUEST, mensagem);
            default -> new ApiException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Falha ao " + operacao + " no Oracle: " + mensagem);
        };
    }

    /** Remove o prefixo "ORA-2000x: " e a pilha "ORA-06512" da mensagem do Oracle. */
    static String limpar(String mensagemOracle) {
        if (mensagemOracle == null) {
            return "Erro de banco de dados";
        }
        String primeiraLinha = mensagemOracle.split("\\R", 2)[0];
        return primeiraLinha.replaceFirst("^ORA-\\d{5}:\\s*", "").trim();
    }
}
