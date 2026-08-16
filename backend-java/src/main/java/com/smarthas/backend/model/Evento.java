package com.smarthas.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * Evento de uso (curso/servico visitado, ou "curso_concluido" para gamificacao).
 * Alimenta o motor de recomendacao, deteccao de tendencias e gamificacao -
 * mesmo papel do EventoORM no backend Python.
 */
@Entity
@Table(name = "eventos")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Evento {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String userId;

    @Column(nullable = false)
    private String tipo;

    @Column(nullable = false)
    private Long referenceId;

    private String categoria;

    @Column(nullable = false)
    @Builder.Default
    private LocalDateTime timestamp = LocalDateTime.now();
}
