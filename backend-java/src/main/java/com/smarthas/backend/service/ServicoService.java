package com.smarthas.backend.service;

import com.smarthas.backend.dto.ServicoRequest;
import com.smarthas.backend.exception.ApiException;
import com.smarthas.backend.model.Servico;
import com.smarthas.backend.repository.ServicoRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ServicoService {

    private final ServicoRepository servicoRepository;

    public ServicoService(ServicoRepository servicoRepository) {
        this.servicoRepository = servicoRepository;
    }

    public List<Servico> listar() {
        return servicoRepository.findAll();
    }

    public Servico buscar(Long id) {
        return servicoRepository.findById(id)
                .orElseThrow(() -> ApiException.notFound("Servico nao encontrado: " + id));
    }

    public Servico criar(ServicoRequest request) {
        Servico servico = Servico.builder()
                .titulo(request.titulo())
                .descricao(request.descricao())
                .categoria(request.categoria())
                .orgao(request.orgao())
                .conteudo(request.conteudo())
                .build();
        return servicoRepository.save(servico);
    }

    public Servico atualizar(Long id, ServicoRequest request) {
        Servico servico = buscar(id);
        servico.setTitulo(request.titulo());
        servico.setDescricao(request.descricao());
        servico.setCategoria(request.categoria());
        servico.setOrgao(request.orgao());
        servico.setConteudo(request.conteudo());
        return servicoRepository.save(servico);
    }

    public void remover(Long id) {
        if (!servicoRepository.existsById(id)) {
            throw ApiException.notFound("Servico nao encontrado: " + id);
        }
        servicoRepository.deleteById(id);
    }
}
