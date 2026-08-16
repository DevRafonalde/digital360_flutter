package com.smarthas.backend.service;

import com.smarthas.backend.dto.IndicacoesResponse;
import com.smarthas.backend.exception.ApiException;
import com.smarthas.backend.model.Curso;
import com.smarthas.backend.model.Usuario;
import com.smarthas.backend.repository.CursoRepository;
import com.smarthas.backend.repository.UsuarioRepository;
import com.smarthas.backend.repository.VinculoCuidadorRepository;
import org.springframework.stereotype.Service;

import java.util.List;

/** Acoes de perfil: virar tutor, indicacoes, e exclusao da propria conta (LGPD). */
@Service
public class PerfilService {

    private final UsuarioRepository usuarioRepository;
    private final CursoRepository cursoRepository;
    private final VinculoCuidadorRepository vinculoRepository;

    public PerfilService(UsuarioRepository usuarioRepository, CursoRepository cursoRepository,
                          VinculoCuidadorRepository vinculoRepository) {
        this.usuarioRepository = usuarioRepository;
        this.cursoRepository = cursoRepository;
        this.vinculoRepository = vinculoRepository;
    }

    /** Auto-atribuicao do papel de tutor - sem fila de aprovacao (mesmo criterio do app). */
    public boolean tornarTutor(String nomeUser) {
        Usuario usuario = buscarUsuario(nomeUser);
        usuario.setIsTutor(true);
        usuarioRepository.save(usuario);
        return true;
    }

    public IndicacoesResponse minhasIndicacoes(String nomeUser) {
        Usuario usuario = buscarUsuario(nomeUser);
        return new IndicacoesResponse(usuario.getNomeUser(), usuario.getTotalIndicacoes());
    }

    /**
     * Exclusao da propria conta (LGPD): rascunhos do proprio tutor sao
     * apagados; cursos ja publicados ficam orfaos (autorId=null) em vez de
     * apagados, para nao quebrar o catalogo de quem ja estuda por eles;
     * vinculos de cuidador (nos dois sentidos) sao removidos.
     */
    public void excluirConta(String nomeUser) {
        Usuario usuario = buscarUsuario(nomeUser);

        List<Curso> rascunhos = cursoRepository.findByAutorIdAndStatus(usuario.getId(), "RASCUNHO");
        cursoRepository.deleteAll(rascunhos);

        List<Curso> publicados = cursoRepository.findByAutorId(usuario.getId());
        publicados.forEach(c -> c.setAutorId(null));
        cursoRepository.saveAll(publicados);

        vinculoRepository.deleteByCuidadorIdOrIdosoId(usuario.getId(), usuario.getId());

        usuarioRepository.delete(usuario);
    }

    private Usuario buscarUsuario(String nomeUser) {
        return usuarioRepository.findByNomeUser(nomeUser)
                .orElseThrow(() -> ApiException.notFound("Usuario nao encontrado: " + nomeUser));
    }
}
