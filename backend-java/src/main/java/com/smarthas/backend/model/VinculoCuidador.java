package com.smarthas.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * Vinculo somente-leitura entre um cuidador e um idoso/tutelado: o cuidador
 * acompanha o progresso, nunca age em nome da pessoa (a conta do idoso
 * continua sendo dele, com seu proprio login).
 */
@Entity
@Table(name = "vinculos_cuidador")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VinculoCuidador {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long cuidadorId;

    @Column(nullable = false)
    private Long idosoId;

    @Column(nullable = false)
    @Builder.Default
    private String status = "ATIVO";

    @Column(nullable = false)
    @Builder.Default
    private LocalDateTime criadoEm = LocalDateTime.now();
}
