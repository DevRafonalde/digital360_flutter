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
- [x] **(26/08, sessão 2) Bug real corrigido no dashboard**: `LoginRequest` do Angular
      mandava o campo `senha`, mas o backend espera `senhaUser` — login sempre falhava.
      Corrigido em `usuario.model.ts` e `login.component.ts`. Confirmado com login real
      pela UI (`admin`/`admin123`) depois do fix.
- [x] **(26/08, sessão 2) Duas páginas novas no dashboard**: Tendências (`/tendencias`)
      e Gamificação/ranking (`/gamificacao/ranking`) — consomem endpoints que o backend
      já tinha pronto mas que não apareciam em nenhuma tela ainda. `ng build` de
      produção limpo depois da adição. Testadas ao vivo (chamam a API real, mostram
      estado vazio corretamente já que ainda não há dados de uso acumulados).
- [x] Dashboard Angular (`dashboard/`) — `npm install` + `ng build` sem erros (revalidado
      depois das mudanças acima).
- [x] Fluxo completo testado ao vivo pela UI, não só por leitura de código: login →
      home (KPIs reais) → cursos (criar/excluir) → pedidos (recalcular risco →
      CRITICO/100 → reagendar) → tendências → gamificação.
- [ ] **Atenção antes de gravar**: o teste acima reagendou o `pedido LM-2026-0002` de
      verdade, então ele está `PENDENTE` no banco agora, não `ATRASADO`. Resetar os
      dados de demo antes de gravar (parar o backend, apagar `backend-java/data/`, subir
      de novo — o `DataSeeder` recria os 4 pedidos originais).
- [x] App Flutter — seletor de ambiente de backend, `dart analyze` limpo, `flutter test`
      com as 85 verificações passando.
- [x] Decidido: `backend-java/`, `dashboard/` e as mudanças no Flutter foram commitados
      (`5dad8f2`) e enviados via PR para o repositório compartilhado — push feito para
      `eamvzs/digital360_flutter` (fork), com **PR #2 aberto** contra
      `DevRafonalde/digital360_flutter:main`. Link do PR já está em `ENTREGA_FASE5/LINKS.txt`.

## Documentação e slides — Word/PowerPoint reais, abertos e validados no Office
- [x] `DOCUMENTACAO_FASE5.docx` + `DOCUMENTACAO_FASE5.pdf` (13 páginas, capa com RM de
      cada integrante, sumário, Partes 1/2/3, tabela completa de 33 endpoints).
- [x] `SLIDES_FASE5.pptx` + `SLIDES_FASE5.pdf` (10 slides, 16:9, diagramas de arquitetura,
      roadmap e mockup do dashboard).
- [x] Gramática e acentuação revisadas nos dois.
- [x] **(26/08, sessão 3) Fotos dos 5 integrantes inseridas** — recuperadas de uma
      entrega anterior do grupo (`Downloads\Digital360-FIAP.pdf`, atividade Leroy
      Merlin), extraídas com PyMuPDF. Conferido byte a byte: cada foto bate com o nome
      certo (Eduardo→foto1, Otávio→foto2, Enzo→foto3, Rafael→foto4, Guilherme→foto5).
- [x] **(27/08, sessão 4) Bug real corrigido nas fotos**: a primeira inserção esticou a
      foto (moldura quadrada forçada sobre imagem retangular) e deixou um resquício
      preto do recorte circular antigo por trás — ficou com "cara de bug". Causa raiz: as
      fotos extraídas do PDF tinham a margem preta do recorte circular ANTIGO ainda
      colada nos pixels (não eram transparentes de verdade). Corrigido: recortei cada
      foto exatamente no limite do conteúdo real (removendo a margem preta sem
      distorcer), com `PIL`/`numpy`, antes de inserir — sem esticar, sem duplo recorte.
      `.docx` corrigido; `.pptx` ganhou fotos novas no redesenho abaixo.
- [x] **(27/08, sessão 4) PPTX redesenhado do zero** — o deck tinha "cara de IA" (caixas
      "Honestidade técnica" com borda colorida, ícones genéricos em círculo, cores
      azul-padrão). Reconstruído via `pptxgenjs` com paleta própria do projeto (fundo
      grafite `#14141B`, laranja `#FF6B35` do app, verde-água `#00D9A3`, magenta FIAP
      `#ED0973`), layouts variados por slide (hero stat assimétrico, pull-quote,
      timeline, diagrama de camadas, mock de painel Swagger/dashboard com dados reais em
      vez do placeholder "[Espaço para PRINT]"), tipografia Cambria+Calibri, texto
      alinhado à esquerda. Mesmo conteúdo técnico de antes (extraído slide a slide antes
      de reescrever), só a apresentação mudou. `.docx` manteve o conteúdo/estrutura
      originais — só as fotos foram corrigidas ali (retrabalho rápido, não redesenho).
      Validado estruturalmente (`python-pptx`: 10 slides, texto UTF-8 correto conferido
      num dump à parte, 5 fotos na posição certa sem sobreposição).
- [x] **(27/08, sessão 4) Retrabalho rápido no `.docx`**: removidas as 4 caixinhas com
      borda colorida e fundo sombreado tipo "Verificado de verdade" / "Tudo neste
      documento foi validado rodando de verdade..." — eram um clichê de relatório de IA
      (o texto viraram parágrafos normais, sem caixa, sem negrito de "selo de prova").
      Conteúdo técnico mantido, só a formatação mudou.
- [x] **(27/08, sessão 4) Conferência visual real feita** — LibreOffice instalou na 2ª
      tentativa (precisou de confirmação manual de administrador). Renderizei os 10
      slides e as 11 páginas do doc em imagem e revisei um por um: fotos circulares
      limpas em ambos, mock do dashboard (slide 7) com barra lateral de navegação de
      verdade (Início/Cursos/Serviços/Pedidos/Tendências/Gamificação, "Pedidos" marcado
      como ativo) em vez de só uma tabela solta, e um bug de negrito no slide 9 (texto
      de corpo saindo em negrito/branco por engano) corrigido.
      **Falta só**: exportar os PDFs de dentro do Word/PowerPoint (não tenho Office real
      aqui, só LibreOffice para conferência) — **Arquivo > Salvar como PDF** no Word,
      **Arquivo > Exportar > Criar PDF/XPS** no PowerPoint.
- [ ] Confirmar se `https://github.com/DevRafonalde/digital360_flutter` é o link que o
      grupo quer entregar (já preenchido no documento e nos slides).
- [ ] Preencher o link do vídeo do YouTube depois de publicado (documento e slides) —
      fazer isso na mesma passada de edição em que for conferir as fotos, antes de
      exportar o PDF final.
- [ ] Trocar o box "[Espaço para PRINT do Swagger UI]" (slide 6) por uma captura real,
      se quiser.
- [ ] Atualizar a árvore de pastas da seção 3.2 do `DOCUMENTACAO_FASE5.docx` — hoje só
      lista `pages/{login,layout,home,cursos,servicos,pedidos}`, faltam `tendencias/` e
      `gamificacao/` (adicionadas em 26/08). Fazer isso na mesma passada acima.

## Vídeo
- [x] `ROTEIRO_VIDEO_FASE5.md` — roteiro cronometrado com a demo do backend + dashboard + app.
      (26/08: corrigida a fala de 4:30-4:50, que dizia que comunidade/gamificação
      seguiam só no Python — na verdade o Java já cobre os 33 endpoints, igual ao slide 9
      e à documentação. A fala agora bate com os dois.)
- [x] **Backend confirmado rodando de verdade no terminal normal do Eduardo** (fora do
      Claude Code) — `Tomcat started on port 8080`, H2 conectado, login/cursos/pedidos/
      recalcular-risco/reagendar/tendências/gamificação testados via curl e pela UI do
      dashboard com sucesso. (Dentro do Claude Code o mesmo comando falha por um bug de
      sandbox de processos do Claude Code/Cowork no Windows — não é do projeto — por
      isso a validação final precisava ser no terminal do usuário mesmo.)
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
