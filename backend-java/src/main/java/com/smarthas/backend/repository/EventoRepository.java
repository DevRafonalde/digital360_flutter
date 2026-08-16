package com.smarthas.backend.repository;

import com.smarthas.backend.model.Evento;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface EventoRepository extends JpaRepository<Evento, Long> {
    List<Evento> findByUserId(String userId);
    long countByTipo(String tipo);
}
