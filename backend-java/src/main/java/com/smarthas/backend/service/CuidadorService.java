package com.smarthas.backend.service;

import com.smarthas.backend.dto.ResumoIdosoResponse;
import com.smarthas.backend.dto.VincularCuidadorRequest;
import com.smarthas.backend.dto.VinculoCuidadorResponse;
import com.smarthas.backend.exception.ApiException;
import com.smarthas.backend.model.Usuario;
import com.smarthas.backend.model.VinculoCuidador;
import com.smarthas.backend.repository.UsuarioRepository;
import com.smarthas.backend.repository.VinculoCuidadorRepository;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Modo cuidador: vinculo somente-leitura, direto por codigo (o nomeUser do
 * idoso), sem fila de aprovacao - o cuidador acompanha, nunca age em nome do
 * idoso. Espelha o bloco de cuidador do backend Python.
 */
@Service
public class CuidadorService {

    private final VinculoCuidadorRepository vinculoRepository;
    private final UsuarioRepository usuarioRepository;
    private final GamificacaoService gamificacaoService;

    public CuidadorService(VinculoCuidadorRepository vinculoRepository, UsuarioRepository usuarioRepository,
                            GamificacaoService gamificacaoService) {
        this.vinculoRepository = vinculoRepository;
        this.usuarioRepository = usuarioRepository;
        this.gamificacaoService = gamificacaoService;
    }

    public void vincular(String cuidadorNomeUser, VincularCuidadorRequest request) {
        if (request.codigoIdoso().equals(cuidadorNomeUser)) {
            throw ApiException.unprocessable("Voce nao pode se vincular a si mesmo");
        }
        Usuario cuidador = buscarUsuario(cuidadorNomeUser);
        Usuario idoso = usuarioRepository.findByNomeUser(request.codigoIdoso())
                .orElseThrow(() -> ApiException.notFound("Codigo de convite nao encontrado"));

        if (vinculoRepository.findByCuidadorIdAndIdosoId(cuidador.getId(), idoso.getId()).isPresent()) {
            throw ApiException.conflict("Vinculo ja existe");
        }

        vinculoRepository.save(VinculoCuidador.builder()
                .cuidadorId(cuidador.getId())
                .idosoId(idoso.getId())
                .build());
    }

    public List<VinculoCuidadorResponse> listarVinculos(String cuidadorNomeUser) {
        Usuario cuidador = buscarUsuario(cuidadorNomeUser);
        return vinculoRepository.findByCuidadorId(cuidador.getId()).stream()
                .map(v -> {
                    Usuario idoso = usuarioRepository.findById(v.getIdosoId())
                            .orElseThrow(() -> ApiException.notFound("Idoso nao encontrado"));
                    return new VinculoCuidadorResponse(idoso.getNomeUser(), idoso.getNomeAmigavel(), v.getCriadoEm());
                })
                .toList();
    }

    public ResumoIdosoResponse resumoDoIdoso(String cuidadorNomeUser, String idosoNomeUser) {
        Usuario cuidador = buscarUsuario(cuidadorNomeUser);
        Usuario idoso = usuarioRepository.findByNomeUser(idosoNomeUser)
                .orElseThrow(() -> ApiException.notFound("Usuario nao encontrado"));

        vinculoRepository.findByCuidadorIdAndIdosoId(cuidador.getId(), idoso.getId())
                .orElseThrow(() -> ApiException.forbidden("Voce nao tem vinculo de cuidador com este usuario"));

        var stats = gamificacaoService.resumoDe(idoso.getNomeUser());
        return new ResumoIdosoResponse(idoso.getNomeAmigavel(), stats.cursosConcluidos(), stats.sequenciaDias(), stats.pontos());
    }

    private Usuario buscarUsuario(String nomeUser) {
        return usuarioRepository.findByNomeUser(nomeUser)
                .orElseThrow(() -> ApiException.notFound("Usuario nao encontrado: " + nomeUser));
    }
}
