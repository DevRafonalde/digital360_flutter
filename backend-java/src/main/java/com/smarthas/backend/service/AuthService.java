package com.smarthas.backend.service;

import com.smarthas.backend.dto.LoginRequest;
import com.smarthas.backend.dto.LoginResponse;
import com.smarthas.backend.dto.RegisterRequest;
import com.smarthas.backend.exception.ApiException;
import com.smarthas.backend.model.Perfil;
import com.smarthas.backend.model.Usuario;
import com.smarthas.backend.repository.UsuarioRepository;
import com.smarthas.backend.security.JwtService;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
public class AuthService {

    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;

    public AuthService(UsuarioRepository usuarioRepository, PasswordEncoder passwordEncoder,
                        AuthenticationManager authenticationManager, JwtService jwtService) {
        this.usuarioRepository = usuarioRepository;
        this.passwordEncoder = passwordEncoder;
        this.authenticationManager = authenticationManager;
        this.jwtService = jwtService;
    }

    public LoginResponse login(LoginRequest request) {
        // Delega a validacao de credenciais ao AuthenticationManager (Spring Security),
        // que usa CustomUserDetailsService + PasswordEncoder por baixo dos panos.
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.nomeUser(), request.senhaUser()));

        Usuario usuario = usuarioRepository.findByNomeUser(request.nomeUser())
                .orElseThrow(() -> ApiException.notFound("Usuario nao encontrado"));

        String accessToken = jwtService.generateAccessToken(usuario.getNomeUser(), usuario.getPerfil().name());
        String refreshToken = jwtService.generateRefreshToken(usuario.getNomeUser(), usuario.getPerfil().name());

        return LoginResponse.from(usuario, accessToken, refreshToken);
    }

    /** Renova a sessao a partir do refresh token (usado pelo app quando um access token expira). */
    public LoginResponse refresh(String refreshToken) {
        String nomeUser;
        try {
            nomeUser = jwtService.extractNomeUser(refreshToken);
        } catch (Exception ex) {
            throw ApiException.unauthorized("Refresh token invalido ou expirado");
        }

        Usuario usuario = usuarioRepository.findByNomeUser(nomeUser)
                .orElseThrow(() -> ApiException.notFound("Usuario nao encontrado"));

        String novoAccessToken = jwtService.generateAccessToken(usuario.getNomeUser(), usuario.getPerfil().name());
        String novoRefreshToken = jwtService.generateRefreshToken(usuario.getNomeUser(), usuario.getPerfil().name());

        return LoginResponse.from(usuario, novoAccessToken, novoRefreshToken);
    }

    public void register(RegisterRequest request) {
        if (!Boolean.TRUE.equals(request.aceitouPolitica())) {
            throw ApiException.unprocessable("E necessario aceitar a politica de privacidade");
        }
        if (usuarioRepository.existsByNomeUser(request.nomeUser())) {
            throw new ApiException(HttpStatus.CONFLICT, "Ja existe um usuario com este nomeUser");
        }

        Usuario usuario = Usuario.builder()
                .nomeAmigavel(blankToNomeUser(request.nomeAmigavel(), request.nomeUser()))
                .nomeUser(request.nomeUser())
                .senhaHash(passwordEncoder.encode(request.senhaUser()))
                .perfil(Perfil.USUARIO)
                .nomeCompleto(request.nomeCompleto() != null ? request.nomeCompleto() : "")
                .cpf(request.cpf() != null ? request.cpf() : "")
                .aceitouPoliticaEm(LocalDateTime.now())
                .build();

        usuarioRepository.save(usuario);

        // Codigo de indicacao e o proprio nomeUser de quem indicou (ja unico). Silencioso se
        // o codigo nao existir, para nao vazar quais nomes de usuario sao validos.
        if (request.codigoIndicacao() != null && !request.codigoIndicacao().equals(request.nomeUser())) {
            usuarioRepository.findByNomeUser(request.codigoIndicacao()).ifPresent(indicador -> {
                indicador.setTotalIndicacoes(indicador.getTotalIndicacoes() + 1);
                usuarioRepository.save(indicador);
            });
        }
    }

    private String blankToNomeUser(String nomeAmigavel, String nomeUser) {
        return (nomeAmigavel == null || nomeAmigavel.isBlank()) ? nomeUser : nomeAmigavel;
    }
}
