# Checklist de entrega — Fase 5 (FIAP ON)

## Pasta `docs/fase5/` (limpa — só o que vai pra entrega)
| Arquivo | O que é |
|---|---|
| `DOCUMENTACAO_FASE5.docx` | Documento fonte, editável no Word (Partes 1/2/3, 33 endpoints, limitações) |
| `DOCUMENTACAO_FASE5.pdf` | PDF exportado direto do `.docx` acima — sempre regenere a partir dele |
| `SLIDES_FASE5.pptx` | Slides fonte, editáveis no PowerPoint (10 slides, com diagramas) |
| `SLIDES_FASE5.pdf` | PDF exportado direto do `.pptx` acima — sempre regenere a partir dele |
| `ROTEIRO_VIDEO_FASE5.md` | Roteiro cronometrado (~5 min) para gravar o vídeo |
| `CHECKLIST_ENTREGA_FASE5.md` | Este arquivo |

Removidos por serem redundantes (HTML/rascunho .md que geraram as primeiras versões, e o
roteiro de conteúdo dos slides — hoje esse conteúdo já está de verdade no `.pptx`).

## Codigo (pronto e validado rodando de verdade)
- [x] Backend Spring Boot (`backend-java/`) — cobertura completa: 33 endpoints (núcleo AI
      Logistics + comunidade/fórum/gamificação/cuidador/indicação/marketplace de
      tutores/recomendações/tendências/LGPD). Compilado e rodado de verdade
      (`mvn spring-boot:run`), todos os fluxos testados via `curl`, 2 bugs reais
      encontrados e corrigidos.
- [x] Dashboard Angular (`dashboard/`) — `npm install` + `ng build` sem erros.
- [x] App Flutter — seletor de ambiente de backend, `dart analyze` limpo, `flutter test`
      com as 85 verificações passando.
- [ ] Decidir se `backend-java/`, `dashboard/` e as mudanças no Flutter entram no
      commit/push do repositório compartilhado com o Rafael (estão untracked, de
      propósito).

## Documentação e slides — Word/PowerPoint reais, abertos e validados no Office
- [x] `DOCUMENTACAO_FASE5.docx` + `DOCUMENTACAO_FASE5.pdf` (13 páginas, capa com RM de
      cada integrante, sumário, Partes 1/2/3, tabela completa de 33 endpoints).
- [x] `SLIDES_FASE5.pptx` + `SLIDES_FASE5.pdf` (10 slides, 16:9, diagramas de arquitetura,
      roadmap e mockup do dashboard).
- [x] Gramática e acentuação revisadas nos dois.
- [ ] Inserir as fotos dos 5 integrantes (hoje são placeholders "FOTO"): edite direto no
      `.docx`/`.pptx` e depois **Arquivo > Salvar como PDF** (Word) ou
      **Arquivo > Exportar > Criar PDF/XPS** (PowerPoint) para regerar o PDF.
- [ ] Confirmar se `https://github.com/DevRafonalde/digital360_flutter` é o link que o
      grupo quer entregar (já preenchido no documento e nos slides).
- [ ] Preencher o link do vídeo do YouTube depois de publicado (documento e slides).
- [ ] Trocar o box "[Espaço para PRINT do Swagger UI]" (slide 6) por uma captura real,
      se quiser.

## Vídeo
- [x] `ROTEIRO_VIDEO_FASE5.md` — roteiro cronometrado com a demo do backend + dashboard + app.
- [ ] Gravar o vídeo (backend e dashboard rodando de verdade).
- [ ] Publicar no YouTube como "Não listado".
- [ ] Testar o link em aba anônima.
- [ ] Adicionar o link do vídeo no documento e nos slides (e regerar os PDFs).

## Empacotamento final
- [ ] Reunir num único `.zip`: `DOCUMENTACAO_FASE5.pdf`, código (ou link do GitHub),
      `SLIDES_FASE5.pdf`, e o link do vídeo (dentro do documento/slides).
- [ ] Testar que o `.zip` abre e funciona localmente após descompactado.
- [ ] Conferir o cadastro do grupo (alunos/RMs) na plataforma FIAP ON antes do envio.
- [ ] Apenas uma entrega em nome do grupo, pelo aluno que cadastrou o grupo.
