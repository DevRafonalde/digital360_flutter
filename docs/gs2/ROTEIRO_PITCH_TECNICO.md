# Roteiro – Vídeo Pitch Técnico (máx. 5 min) · vale nota na GS2

**Objetivo:** demonstrar o app funcionando e explicar as escolhas técnicas, as funcionalidades
e o modelo de dados.

**Regras da entrega**
- [ ] No máximo **5:00**. Mire em 4:40.
- [ ] Publicar no YouTube como **Não listado** e testar o link em uma aba anônima.
- [ ] Colar o link em `docs/gs2/LINK_PITCH_TECNICO.txt`.

## Antes de gravar
- [ ] Docker Desktop aberto e, na raiz do repositório: `bash deploy/deploy_homolog.sh`
      (sobe o Oracle e a API Java, instala o PL/SQL e valida)
- [ ] `bash deploy/app_web_docker.sh` e abrir http://localhost:5000 no Chrome
- [ ] No app: Configurações → Conexão (avançado) → **Java**. Login `joao` / `123456`
- [ ] Swagger aberto em http://localhost:8080/swagger-ui.html, com login `admin`/`admin123` e
      token colado em **Authorize**
- [ ] VS Code aberto em `lib/`, com as abas `main.dart`, `guia_screen.dart`,
      `api_service.dart` e `README.md` (seção de memória)
- [ ] `database-oracle/DER_SmartHAS.png` e `MER_SmartHAS.md` (aberto no GitHub, que desenha o
      diagrama) prontos para mostrar
- [ ] Microfone testado e permissão de microfone liberada no Chrome (busca por voz)

---

## 0:00 – 0:25 | Abertura (câmera ou slide)
> "Somos o grupo Digital 360. Nosso app em Flutter ajuda idosos e pessoas com deficiência a
> usar serviços digitais com autonomia. Vamos mostrar as três funcionalidades principais, a
> arquitetura, as práticas de memória e o banco com PL/SQL."

## 0:25 – 0:55 | Stack e arquitetura
Mostre `docs/architecture.svg` ou o README.
> "O app é Flutter, com um único código para Android, iOS e web. O estado fica no Provider,
> com um ChangeNotifier por domínio. O fluxo é tela, Provider, Service e Model. O back-end é
> Java com Spring Boot e JWT, ligado a um Oracle com PL/SQL, tudo em Docker e com CI no
> GitHub Actions."

## 0:55 – 1:20 | Login e acessibilidade
1. Errar a senha uma vez para mostrar a mensagem amigável e depois entrar como `joao`.
2. Perfil → Configurações: aumentar a fonte e trocar para o tema escuro.
> "O público tem baixa visão e pouca prática digital. Por isso, fonte ajustável, alto
> contraste, voz e confirmação antes de ações sensíveis."

## 1:20 – 1:50 | Funcionalidade 1: trilhas de aprendizagem
Cursos → "Usando o gov.br" → abrir um módulo → tocar em **Ouvir** → avançar o progresso.
> "O progresso é salvo, o conteúdo é lido em voz alta pelo flutter_tts e, ao concluir, o app
> gera um certificado em PDF no próprio aparelho."

## 1:50 – 2:20 | Funcionalidade 2: guia de serviços públicos
Guia → **busca por voz**, dizendo "INSS" → abrir "Consultar benefício do INSS" → ouvir o passo
a passo → favoritar.
> "A busca por voz usa o speech_to_text, e os favoritos e o histórico ficam salvos no
> aparelho."

## 2:20 – 3:05 | Funcionalidade 3: acompanhamento de entregas
1. Logística → abrir um pedido de risco ALTO e mostrar o badge de risco e o clima.
   > "O risco considera o clima real da região, que vem da API Open-Meteo."
2. **Reagendar** com 1 toque e confirmar.
3. Swagger: `POST /oracle/entregas/2/recalcular-risco` → mostrar o retorno CRITICO.
   > "Esse cálculo roda no Oracle, na procedure SP_RECALCULAR_RISCO do package PKG_SH_RISCO.
   > Ela grava o histórico e abre um alerta automaticamente."
4. Mostrar rapidamente a aba Mapa.

## 3:05 – 3:50 | Gerenciamento de memória (VS Code)
1. `assistente_screen.dart`, método `dispose()`:
   > "Todo controller de tela é liberado no dispose, para não vazar memória."
2. Um `if (!mounted) return;` depois de um `await`.
3. `api_service.dart`: o singleton com um único `http.Client` e o timeout de 10 s.
4. Uma tela com `ListView.builder`:
   > "As listas são preguiçosas, então só o que está visível é construído. Além disso, usamos
   > construtores const e rebuild seletivo com context.watch e context.read."
5. (Opcional, mostra maturidade) README → "Ponto de melhoria identificado":
   > "Mapeamos sete controllers de diálogos que ainda serão refatorados."

## 3:50 – 4:30 | Modelo de dados e PL/SQL
1. MER: "o modelo conceitual, com usuário, curso, serviço, pedido, sensor e alerta. Matrícula
   e favorito são relacionamentos N:N."
2. DER: "que vira 12 tabelas no Oracle."
3. Swagger: `GET /oracle/alertas/auditoria`:
   > "A trigger TRG_SH_ALERTA_AUDITORIA registra quem mudou cada alerta. A TRG_SH_PEDIDO_ENTREGUE
   > fecha os alertas quando a entrega é concluída. Os quatro packages automatizam o risco, os
   > alertas de sensores, os indicadores por usuário e as buscas dinâmicas."

## 4:30 – 4:50 | Encerramento
> "Toda a documentação está no repositório: README.md, README.txt, MER, DER e scripts. O
> projeto contribui com os ODS 10 e 4, de inclusão e educação digital. Obrigado!"

---

## Se algo falhar ao vivo
- Sem Docker ou back-end: rode o app em modo **Mock** e use as imagens de
  `docs/fase7/evidencias/telas_app/` para a parte do Oracle.
- Busca por voz não funcionou: digite "INSS" e diga que a voz depende da permissão do
  navegador.
