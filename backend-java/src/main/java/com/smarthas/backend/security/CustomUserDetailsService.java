package com.smarthas.backend.security;

import com.smarthas.backend.model.Usuario;
import com.smarthas.backend.repository.UsuarioRepository;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
public class CustomUserDetailsService implements UserDetailsService {

    private final UsuarioRepository usuarioRepository;

    public CustomUserDetailsService(UsuarioRepository usuarioRepository) {
        this.usuarioRepository = usuarioRepository;
    }

    @Override
    public UserDetails loadUserByUsername(String nomeUser) throws UsernameNotFoundException {
        Usuario usuario = usuarioRepository.findByNomeUser(nomeUser)
                .orElseThrow(() -> new UsernameNotFoundException("Usuario nao encontrado: " + nomeUser));

        return User.builder()
                .username(usuario.getNomeUser())
                .password(usuario.getSenhaHash())
                .authorities("ROLE_" + usuario.getPerfil().name())
                .build();
    }
}
