package com.smarthas.backend.service;

import com.smarthas.backend.dto.PedidoLogisticoRequest;
import com.smarthas.backend.dto.RiscoLogisticoResponse;
import com.smarthas.backend.exception.ApiException;
import com.smarthas.backend.model.PedidoLogistico;
import com.smarthas.backend.repository.PedidoLogisticoRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class PedidoLogisticoService {

    private final PedidoLogisticoRepository pedidoRepository;
    private final RiscoEngine riscoEngine;

    public PedidoLogisticoService(PedidoLogisticoRepository pedidoRepository, RiscoEngine riscoEngine) {
        this.pedidoRepository = pedidoRepository;
        this.riscoEngine = riscoEngine;
    }

    public List<PedidoLogistico> listar() {
        return pedidoRepository.findAll();
    }

    public PedidoLogistico buscar(Long id) {
        return pedidoRepository.findById(id)
                .orElseThrow(() -> ApiException.notFound("Pedido nao encontrado: " + id));
    }

    public PedidoLogistico criar(PedidoLogisticoRequest request) {
        PedidoLogistico pedido = PedidoLogistico.builder()
                .codigoPedido(request.codigoPedido())
                .produto(request.produto())
                .tipoProduto(request.tipoProduto())
                .regiaoEntrega(request.regiaoEntrega())
                .distanciaKm(request.distanciaKm())
                .prazoPrometido(request.prazoPrometido())
                .statusAtual(request.statusAtual())
                .parceiroLogistico(request.parceiroLogistico())
                .estoqueDisponivel(request.estoqueDisponivel())
                .historicoAtrasos(request.historicoAtrasos() != null ? request.historicoAtrasos() : 0)
                .reagendamentos(request.reagendamentos() != null ? request.reagendamentos() : 0)
                .latitude(request.latitude())
                .longitude(request.longitude())
                .build();
        return pedidoRepository.save(pedido);
    }

    public PedidoLogistico atualizar(Long id, PedidoLogisticoRequest request) {
        PedidoLogistico pedido = buscar(id);
        pedido.setCodigoPedido(request.codigoPedido());
        pedido.setProduto(request.produto());
        pedido.setTipoProduto(request.tipoProduto());
        pedido.setRegiaoEntrega(request.regiaoEntrega());
        pedido.setDistanciaKm(request.distanciaKm());
        pedido.setPrazoPrometido(request.prazoPrometido());
        pedido.setStatusAtual(request.statusAtual());
        pedido.setParceiroLogistico(request.parceiroLogistico());
        pedido.setEstoqueDisponivel(request.estoqueDisponivel());
        pedido.setHistoricoAtrasos(request.historicoAtrasos() != null ? request.historicoAtrasos() : pedido.getHistoricoAtrasos());
        pedido.setReagendamentos(request.reagendamentos() != null ? request.reagendamentos() : pedido.getReagendamentos());
        pedido.setLatitude(request.latitude());
        pedido.setLongitude(request.longitude());
        return pedidoRepository.save(pedido);
    }

    public void remover(Long id) {
        if (!pedidoRepository.existsById(id)) {
            throw ApiException.notFound("Pedido nao encontrado: " + id);
        }
        pedidoRepository.deleteById(id);
    }

    public RiscoLogisticoResponse recalcularRisco(Long id, int impactoClima) {
        PedidoLogistico pedido = buscar(id);
        return riscoEngine.calcular(pedido, impactoClima);
    }

    /**
     * Usado pela tela "Reagendar entrega" do app: soma ao contador de reagendamentos e
     * volta o status para PENDENTE (mesmo comportamento do MockData.reagendarEntrega()
     * do app Flutter, para o resultado bater com o modo mock).
     */
    public PedidoLogistico reagendar(Long id) {
        PedidoLogistico pedido = buscar(id);
        pedido.setReagendamentos(pedido.getReagendamentos() + 1);
        pedido.setStatusAtual("PENDENTE");
        return pedidoRepository.save(pedido);
    }
}
