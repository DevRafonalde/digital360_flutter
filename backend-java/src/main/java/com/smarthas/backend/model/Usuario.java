package com.smarthas.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

@Entity
@Table(name = "usuarios")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Usuario {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String nomeAmigavel;

    @Column(nullable = false, unique = true)
    private String nomeUser;

    @Column(nullable = false)
    private String senhaHash;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Perfil perfil;

    @Column(nullable = false)
    @Builder.Default
    private String nomeCompleto = "";

    @Column(nullable = false)
    @Builder.Default
    private String cpf = "";

    @Column(nullable = false)
    @Builder.Default
    private Boolean isTutor = false;

    @Column(nullable = false)
    @Builder.Default
    private Integer totalIndicacoes = 0;

    private LocalDateTime aceitouPoliticaEm;
}
