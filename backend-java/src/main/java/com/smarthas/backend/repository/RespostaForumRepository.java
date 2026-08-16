package com.smarthas.backend.repository;

import com.smarthas.backend.model.RespostaForum;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface RespostaForumRepository extends JpaRepository<RespostaForum, Long> {
    List<RespostaForum> findByPerguntaIdOrderByCriadoEm(Long perguntaId);
    long countByPerguntaId(Long perguntaId);
}
