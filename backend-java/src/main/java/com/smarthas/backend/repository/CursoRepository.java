package com.smarthas.backend.repository;

import com.smarthas.backend.model.Curso;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CursoRepository extends JpaRepository<Curso, Long> {
    List<Curso> findByStatus(String status);
    List<Curso> findByAutorId(Long autorId);
    List<Curso> findByAutorIdAndStatus(Long autorId, String status);
    long countByStatus(String status);
    long countByOrigem(String origem);
}
