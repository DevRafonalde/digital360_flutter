package com.smarthas.backend.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.util.Date;
import java.util.function.Function;

/**
 * Emissao e validacao de JWT (access + refresh). Chave HMAC unica configurada
 * via smarthas.jwt.secret (application.properties / variavel de ambiente).
 */
@Service
public class JwtService {

    private final SecretKey key;
    private final long accessExpirationMs;
    private final long refreshExpirationMs;

    public JwtService(
            @Value("${smarthas.jwt.secret}") String secret,
            @Value("${smarthas.jwt.access-expiration-ms}") long accessExpirationMs,
            @Value("${smarthas.jwt.refresh-expiration-ms}") long refreshExpirationMs
    ) {
        this.key = Keys.hmacShaKeyFor(secret.getBytes());
        this.accessExpirationMs = accessExpirationMs;
        this.refreshExpirationMs = refreshExpirationMs;
    }

    public String generateAccessToken(String nomeUser, String perfil) {
        return buildToken(nomeUser, perfil, accessExpirationMs);
    }

    public String generateRefreshToken(String nomeUser, String perfil) {
        return buildToken(nomeUser, perfil, refreshExpirationMs);
    }

    private String buildToken(String subject, String perfil, long expirationMs) {
        Date now = new Date();
        return Jwts.builder()
                .subject(subject)
                .claim("perfil", perfil)
                .issuedAt(now)
                .expiration(new Date(now.getTime() + expirationMs))
                .signWith(key)
                .compact();
    }

    public String extractNomeUser(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    public boolean isTokenValid(String token, UserDetails userDetails) {
        String nomeUser = extractNomeUser(token);
        return nomeUser.equals(userDetails.getUsername()) && !isTokenExpired(token);
    }

    private boolean isTokenExpired(String token) {
        return extractClaim(token, Claims::getExpiration).before(new Date());
    }

    private <T> T extractClaim(String token, Function<Claims, T> resolver) {
        Claims claims = Jwts.parser().verifyWith(key).build().parseSignedClaims(token).getPayload();
        return resolver.apply(claims);
    }
}
