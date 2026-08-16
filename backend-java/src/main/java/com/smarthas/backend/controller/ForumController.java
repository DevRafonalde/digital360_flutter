package com.smarthas.backend.controller;

import com.smarthas.backend.dto.CriarPerguntaRequest;
import com.smarthas.backend.dto.CriarRespostaRequest;
import com.smarthas.backend.dto.PerguntaForumResponse;
import com.smarthas.backend.service.ForumService;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/forum/perguntas")
@Tag(name = "Forum", description = "Perguntas e respostas da comunidade")
@SecurityRequirement(name = "bearerAuth")
public class ForumController {

    private final ForumService forumService;

    public ForumController(ForumService forumService) {
        this.forumService = forumService;
    }

    @PostMapping
    public ResponseEntity<PerguntaForumResponse> criarPergunta(Authentication authentication, @Valid @RequestBody CriarPerguntaRequest request) {
        var criada = forumService.criarPergunta(authentication.getName(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(criada);
    }

    @GetMapping
    public List<PerguntaForumResponse> listarPerguntas() {
        return forumService.listarPerguntas();
    }

    @GetMapping("/{id}")
    public PerguntaForumResponse detalhe(@PathVariable Long id) {
        return forumService.detalhe(id);
    }

    @PostMapping("/{id}/respostas")
    public ResponseEntity<PerguntaForumResponse> responder(
            Authentication authentication, @PathVariable("id") Long perguntaId, @Valid @RequestBody CriarRespostaRequest request
    ) {
        var atualizada = forumService.responder(perguntaId, authentication.getName(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(atualizada);
    }
}
