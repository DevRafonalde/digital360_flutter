package com.smarthas.backend.repository;

import com.smarthas.backend.model.AvaliacaoCurso;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AvaliacaoCursoRepository extends JpaRepository<AvaliacaoCurso, Long> {
    List<AvaliacaoCurso> findByCursoId(Long cursoId);
}
