package com.smarthas.backend.repository;

import com.smarthas.backend.model.PerguntaForum;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PerguntaForumRepository extends JpaRepository<PerguntaForum, Long> {
    List<PerguntaForum> findAllByOrderByCriadoEmDesc();
}
