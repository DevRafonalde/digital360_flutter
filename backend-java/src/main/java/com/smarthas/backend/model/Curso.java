package com.smarthas.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "cursos")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Curso {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String titulo;

    @Column(nullable = false, length = 500)
    private String descricao;

    // BASICO | INTERMEDIARIO | AVANCADO
    @Column(nullable = false)
    private String nivel;

    @Column(nullable = false)
    private Integer cargaHoraria;

    @Column(nullable = false)
    private Integer totalModulos;

    @Column(nullable = false)
    @Builder.Default
    private Integer progresso = 0;

    /** nomeUser do tutor; null = curso oficial ou tutor que excluiu a conta (orfanizado). */
    private Long autorId;

    // OFICIAL | COMUNIDADE
    @Column(nullable = false)
    @Builder.Default
    private String origem = "OFICIAL";

    // RASCUNHO | PUBLICADO
    @Column(nullable = false)
    @Builder.Default
    private String status = "PUBLICADO";

    // EAGER de proposito: colecao pequena (poucos topicos por curso) e este projeto
    // roda com spring.jpa.open-in-view=false, entao um fetch LAZY aqui quebraria a
    // serializacao JSON fora da transacao (LazyInitializationException).
    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "curso_topicos_modulos", joinColumns = @JoinColumn(name = "curso_id"))
    @Column(name = "topico")
    @Builder.Default
    private List<String> topicosModulos = new ArrayList<>();
}
