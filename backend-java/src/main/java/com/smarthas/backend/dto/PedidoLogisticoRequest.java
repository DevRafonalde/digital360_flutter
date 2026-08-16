package com.smarthas.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record PedidoLogisticoRequest(
        @NotBlank(message = "codigoPedido e obrigatorio") String codigoPedido,
        @NotBlank(message = "produto e obrigatorio") String produto,
        @NotBlank(message = "tipoProduto e obrigatorio") String tipoProduto,
        @NotBlank(message = "regiaoEntrega e obrigatoria") String regiaoEntrega,
        @NotNull Integer distanciaKm,
        @NotBlank(message = "prazoPrometido e obrigatorio") String prazoPrometido,
        @NotBlank(message = "statusAtual e obrigatorio") String statusAtual,
        @NotBlank(message = "parceiroLogistico e obrigatorio") String parceiroLogistico,
        @NotNull Boolean estoqueDisponivel,
        Integer historicoAtrasos,
        Integer reagendamentos,
        @NotNull Double latitude,
        @NotNull Double longitude
) {
}
