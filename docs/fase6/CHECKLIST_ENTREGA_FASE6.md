# Smart HAS — Fase 6 (Banco de Dados na Sociedade 5.0) — Guia para o grupo

**Prazo FIAP ON:** 04/10/2026 (até 3 dias depois, a nota máxima cai para 70%).
**Entrega:** um único upload, feito por quem cadastrou o grupo, com todos os RMs.
**Repositório:** https://github.com/DevRafonalde/digital360_flutter — a Fase 6 está no **PR #4** (`fase6`), aguardando o merge do Rafael.

## 1. O que a FIAP pede x status

| # | Pedido no enunciado | Status | Onde está |
|---|---|---|---|
| P1 | Aprimorar a solução: novas funcionalidades, refatoração e documentação das melhorias | ✅ Feito | Doc. seção 1; pacote `plsql` no `backend-java` da Fase 5 |
| P2 | Modelo lógico/físico Oracle das entidades do Smart HAS | ✅ Feito | `database-oracle/01_ddl_tabelas.sql` (11 tabelas) |
| P2 | Implantar as tabelas no Oracle | ✅ Feito e executado | Oracle 23ai Free (Docker); log em `evidencias/01_...` |
| P2 | Importar dados simulados (sensores, usuários, históricos) | ✅ Feito | `02_dados_simulados.sql` (6 usuários, 5 pedidos, 5 sensores, 19 leituras) |
| P2 | Documentar com DER e tabelas | ✅ Feito | `DER_SmartHAS_Fase6.png` + doc. seção 2 |
| P3 | 2+ functions (1 indicador, 1 dados formatados) com EXCEPTION, comentários, IN e RETURN | ✅ Feito (4) | `03_functions.sql` |
| P3 | Usar as functions em consultas SQL | ✅ Feito | `05_testes_e_consultas.sql` (SELECT, WHERE, view) |
| P3 | 2+ procedures (alertas por leitura crítica, relatório por usuário) | ✅ Feito (3) | `04_procedures.sql` |
| P3 | 1 procedure acionada pelo back-end Java (REST → Java → JDBC → Oracle) | ✅ Feito e testado | `backend-java` → `POST /oracle/entregas/{id}/recalcular-risco` → `SP_RECALCULAR_RISCO` |
| P3 | Usar EXCEPTION, IF, LOOP, CURSOR e documentar cada procedure | ✅ Feito | Comentários nos scripts + doc. seção 3 |
| Entrega | Documento em PDF | ✅ Pronto (falta só o link do vídeo) | `SmartHAS_Fase6_Documentacao.pdf` / `.docx` |
| Entrega | Código do projeto ou link do GitHub | 🟡 PR #4 aberto, **falta o Rafael aceitar** | Link já no doc, slides e `LINKS.txt` |
| Entrega | Slides em PDF (até 10) com nome, RM e foto | ✅ Pronto (falta só o link do vídeo) | `SmartHAS_Fase6_Slides.pptx` / `.pdf` (fotos da Atividade 4) |
| Entrega | Vídeo de até 5 min no YouTube (não listado), **com o app rodando** | 🔴 **Falta gravar** | Roteiro em `ROTEIRO_VIDEO_FASE6.md` |
| Entrega | Link do vídeo no documento e nos slides | 🔴 Falta (depende do vídeo) | Trocar `[INSERIR LINK]` |
| Entrega | .ZIP com tudo e upload no FIAP ON com os RMs | 🔴 Falta | Último passo |

## 2. O que já foi validado de verdade
- Scripts rodados no **Oracle Database 23ai Free** (Docker): todos os objetos VALID, nenhum erro de compilação, resultados iguais aos esperados.
- `backend-java` (o mesmo da Fase 5) com o pacote novo `plsql`: **11 testes, 0 falhas**. Subiu conectado ao Oracle, login JWT ok e as 10 chamadas responderam certo, inclusive os erros (404/400/403). A rota `/pedidos` da Fase 5 (H2) continua funcionando.
- Comprovação: pasta `evidencias/`. Para repetir tudo: `database-oracle/testar_no_docker.ps1` (precisa do Docker Desktop).

## 3. O que falta (sugestão de divisão)

| Tarefa | Quem | Tempo |
|---|---|---|
| Revisar e aceitar (merge) o **PR #4** no GitHub | Rafael | 10 min |
| Gravar o vídeo seguindo `ROTEIRO_VIDEO_FASE6.md` e publicar como **Não listado** | 1–2 pessoas | 1–2 h |
| Colar o link do YouTube no `.docx`, no `.pptx` e no `LINKS.txt` e exportar os 2 PDFs de novo | 1 pessoa | 15 min |
| Gerar o .ZIP final e fazer o upload no FIAP ON com os 5 RMs | quem cadastrou o grupo | 10 min |

## 4. Como rodar para gravar o vídeo
1. Docker Desktop aberto → PowerShell nesta pasta:
   `pwsh -ExecutionPolicy Bypass -File .\database-oracle\testar_no_docker.ps1`
2. Banco: SQL Developer ou DBeaver em `localhost:1521`, service `FREEPDB1`, usuário `smarthas`/`smarthas`. Rode `00_executar_tudo.sql` de novo antes de gravar, para zerar os dados.
3. Back-end: Swagger em `http://localhost:8080/swagger-ui.html`. Faça login em `POST /auth/usuarios/login` (`admin`/`admin123`), clique em **Authorize** com o token e use as rotas **Oracle PL/SQL (Fase 6)**.
4. App: rode o app Flutter do repositório, escolha o ambiente **Java** em Configurações → Conexão (avançado) e mostre-o funcionando (o enunciado exige o app rodando no vídeo).
5. Para parar tudo depois: `docker rm -f smarthas-api oracle-free`

## 5. Checklist final antes do upload
- [ ] PR #4 aceito (o link do repositório aponta para a `main` do Rafael)
- [ ] Link do YouTube no documento, nos slides e no `LINKS.txt`
- [ ] PDFs regerados depois das alterações
- [ ] Vídeo abre em aba anônima e mostra o app rodando
- [ ] ZIP abre e todos os arquivos funcionam fora da pasta original
- [ ] Upload único com os 5 RMs: 556970, 550361, 557632, 559136, 557500
