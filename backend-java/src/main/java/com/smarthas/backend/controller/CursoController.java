package com.smarthas.backend.controller;

import com.smarthas.backend.dto.CursoRequest;
import com.smarthas.backend.dto.CursoResponse;
import com.smarthas.backend.dto.GerarRascunhoRequest;
import com.smarthas.backend.dto.GerarRascunhoResponse;
import com.smarthas.backend.model.Curso;
import com.smarthas.backend.service.CursoService;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/cursos")
@Tag(name = "Cursos", description = "Trilhas de aprendizagem: oficiais (ADMIN) e comunitarias (tutores)")
@SecurityRequirement(name = "bearerAuth")
public class CursoController {

    private final CursoService cursoService;

    public CursoController(CursoService cursoService) {
        this.cursoService = cursoService;
    }

    @GetMapping
    public List<CursoResponse> listar() {
        return cursoService.listarPublicados().stream().map(this::paraResponse).toList();
    }

    @GetMapping("/meus")
    public List<CursoResponse> meusCursos(Authentication authentication) {
        return cursoService.meusCursos(authentication.getName()).stream().map(this::paraResponse).toList();
    }

    @GetMapping("/{id}")
    public CursoResponse buscar(@PathVariable Long id) {
        return paraResponse(cursoService.buscar(id));
    }

    @PostMapping
    public ResponseEntity<CursoResponse> criar(Authentication authentication, @Valid @RequestBody CursoRequest request) {
        boolean isAdmin = ehAdmin(authentication);
        Curso criado = cursoService.criar(authentication.getName(), isAdmin, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(paraResponse(criado));
    }

    @PostMapping("/gerar-rascunho")
    public GerarRascunhoResponse gerarRascunho(Authentication authentication, @Valid @RequestBody GerarRascunhoRequest request) {
        String nivel = request.nivel() != null ? request.nivel() : "BASICO";
        return new GerarRascunhoResponse(cursoService.gerarRascunho(authentication.getName(), request.titulo(), nivel));
    }

    @PutMapping("/{id}")
    public CursoResponse atualizar(@PathVariable Long id, @Valid @RequestBody CursoRequest request) {
        return paraResponse(cursoService.atualizar(id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> remover(@PathVariable Long id) {
        cursoService.remover(id);
        return ResponseEntity.noContent().build();
    }

    private CursoResponse paraResponse(Curso curso) {
        return CursoResponse.from(curso, cursoService.resolverAutorNomeUser(curso));
    }

    private boolean ehAdmin(Authentication authentication) {
        return authentication.getAuthorities().contains(new SimpleGrantedAuthority("ROLE_ADMIN"));
    }
}
