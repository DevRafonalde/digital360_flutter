# Consolidando o Smart HAS — Guia para o grupo

**Entrega:** um único upload no FIAP ON, feito por quem cadastrou o grupo, com os 5 RMs.
**Repositório:** https://github.com/DevRafonalde/digital360_flutter

## O que o enunciado pede x status

| Pedido | Status | Onde está |
|---|---|---|
| Agrupar procedures e functions em packages | ✅ Feito | `database-oracle/03` a `06_pkg_*.sql` |
| Trigger de auditoria ou automação | ✅ Feito (2) | `database-oracle/07_triggers.sql` |
| Dynamic SQL | ✅ Feito (2) | `database-oracle/06_pkg_sh_consulta.sql` |
| Documentar os objetos | ✅ Feito | `DOCUMENTACAO.docx` / `.pdf`, seção 2 |
| Pipeline com build e testes | ✅ Feito | `.github/workflows/ci-cd.yml` |
| Deploy do back-end + Oracle | ✅ Feito | Jobs `publicar-imagem` e `deploy-homologacao`, pasta `deploy/` |
| Logs e relatórios | ✅ Feito | Resumo da execução e artefatos `relatorio-*` |
| Documento em PDF | 🟡 Falta o link do vídeo | `DOCUMENTACAO.docx` / `.pdf` |
| Slides em PDF (até 10, com nome, RM e foto) | 🟡 Falta o link do vídeo | `SLIDES.pptx` / `.pdf` |
| Vídeo de até 5 min, não listado, com o app rodando | 🔴 Falta gravar | `ROTEIRO_VIDEO.md` |
| .ZIP e upload no FIAP ON | 🔴 Falta | Último passo |

## Passos finais

1. Revisar e fazer o merge da branch `fase7` na `main`.
2. Gravar o vídeo seguindo `ROTEIRO_VIDEO.md` e publicar como **Não listado**.
3. Trocar `[INSERIR LINK DO VÍDEO]` no `.docx` (1 lugar) e no `.pptx` (slides 1 e 10). Ao abrir o `.docx`, o Word pergunta se deve atualizar os campos: responda **Sim** para atualizar o sumário.
4. Exportar os dois PDFs de novo.
5. Atualizar a pasta de entrega `SmartHAS_Consolidacao` (fora do repositório), compactar em .ZIP e fazer o upload com os RMs 556970, 550361, 557632, 559136 e 557500.

## Antes do upload

- [ ] Merge feito, e o pipeline da `main` terminou com sucesso
- [ ] Vídeo abre em aba anônima e mostra o app rodando
- [ ] Link do vídeo no documento e nos slides
- [ ] PDFs gerados depois da troca do link
- [ ] .ZIP descompactado e aberto fora da pasta original
