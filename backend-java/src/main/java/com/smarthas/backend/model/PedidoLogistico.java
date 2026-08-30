package com.smarthas.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "pedidos_logisticos")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PedidoLogistico {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String codigoPedido;

    @Column(nullable = false)
    private String produto;

    @Column(nullable = false)
    private String tipoProduto;

    @Column(nullable = false)
    private String regiaoEntrega;

    @Column(nullable = false)
    private Integer distanciaKm;

    @Column(nullable = false)
    private String prazoPrometido;

    // PENDENTE | EM_TRANSITO | ENTREGUE | ATRASADO
    @Column(nullable = false)
    private String statusAtual;

    @Column(nullable = false)
    private String parceiroLogistico;

    @Column(nullable = false)
    private Boolean estoqueDisponivel;

    @Column(nullable = false)
    @Builder.Default
    private Integer historicoAtrasos = 0;

    @Column(nullable = false)
    @Builder.Default
    private Integer reagendamentos = 0;

    @Column(nullable = false)
    private Double latitude;

    @Column(nullable = false)
    private Double longitude;
}
