package com.smarthas.backend.repository;

import com.smarthas.backend.model.VinculoCuidador;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface VinculoCuidadorRepository extends JpaRepository<VinculoCuidador, Long> {
    List<VinculoCuidador> findByCuidadorId(Long cuidadorId);
    Optional<VinculoCuidador> findByCuidadorIdAndIdosoId(Long cuidadorId, Long idosoId);
    void deleteByCuidadorIdOrIdosoId(Long cuidadorId, Long idosoId);
}
