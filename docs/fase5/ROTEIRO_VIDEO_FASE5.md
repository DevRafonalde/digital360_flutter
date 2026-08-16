# Roteiro do video — Fase 5 (Mobile Hybrid App e a Sociedade 5.0)

Duracao-alvo: **ate 5 minutos** • Publicar no YouTube como **"Nao listado"** • boa parte
do tempo (~3 min) deve ser demonstracao pratica rodando (app + backend + dashboard).

---

## 0:00 – 0:20 | Abertura
**Tela:** slide 1 (capa, com grupo/RM/fotos).
**Fala:** "Ola! Somos o grupo do projeto Smart HAS - Digital 360, da FIAP. Nesta fase,
evoluimos o back-end com Spring Boot e criamos um dashboard administrativo em Angular
para o nosso app."

## 0:20 – 0:50 | Contexto e decisao de stack
**Tela:** slides 2 e 3.
**Fala:** "O Digital 360 ja e um app maduro em Flutter, com mais de 30 telas e 80 testes
automatizados. Por isso, decidimos nao migrar para React Native nesta fase: o ganho
tecnico real estava em aprofundar a conectividade do app, nao em trocar o framework de
UI. Mantivemos o Flutter e investimos o esforco desta fase num back-end Java robusto e
num painel administrativo web."

## 0:50 – 1:10 | Roadmap
**Tela:** slide 4.
**Fala:** "Ate aqui, ja tinhamos o app completo e um back-end real em Python. Nesta fase,
construimos um segundo back-end, em Java com Spring Boot, cobrindo autenticacao, cursos,
servicos e a camada de AI Logistics, alem do dashboard Angular que consome essa mesma
API. Os proximos passos incluem evoluir o motor de risco para machine learning real."

## 1:10 – 1:50 | Arquitetura do back-end
**Tela:** slides 5 e 6.
**Fala:** "O back-end segue a arquitetura em camadas Controller, Service, Repository e
Model. Usamos autenticacao JWT com access e refresh token, senha protegida com BCrypt, e
autorizacao por perfil: qualquer usuario logado consulta os dados, mas só um
administrador pode criar, editar ou remover cursos, servicos e pedidos. A persistencia é
real, em banco H2, e toda a API é documentada automaticamente com Swagger."

## 1:50 – 2:10 | Arquitetura do dashboard
**Tela:** slide 7.
**Fala:** "O dashboard em Angular consome essa mesma API REST. Usamos HttpClient com um
interceptor que injeta o token em toda chamada, e formularios com two-way binding para
criar e editar os registros direto na tela."

## 2:10 – 4:30 | DEMONSTRACAO AO VIVO (parte principal — ~2min20)
**Tela:** terminal + navegador, mostrando o app rodando de verdade.
1. **Backend**: subir com `mvn spring-boot:run`, abrir o Swagger UI e mostrar rapidamente
   os endpoints de autenticacao e de pedidos.
2. **Login no Swagger ou via curl**: autenticar como `admin` e mostrar o token retornado.
3. **Dashboard Angular**: abrir `http://localhost:4200`, logar como admin, mostrar a
   tela Home com os indicadores, depois Cursos (criar um curso novo pelo formulario),
   depois Pedidos (recalcular o risco de um pedido atrasado e reagendar a entrega).
4. **App Flutter** (se o grupo decidir apontar o app para este backend durante a demo):
   mostrar o login e uma tela consumindo os mesmos dados criados no dashboard.
**Fala de fechamento da demo:** "Isso ja esta funcionando de ponta a ponta: o backend
Java persiste os dados, o dashboard os gerencia, e o mesmo contrato de API pode
alimentar o app mobile."

## 4:30 – 4:50 | Limitacoes e proximos passos
**Tela:** slide 9.
**Fala:** "O escopo deste back-end Java cobre o nucleo do dominio, autenticacao, cursos,
servicos e AI Logistics, de proposito: os recursos mais recentes do app, como comunidade
e gamificacao, continuam no back-end Python do time. O proximo passo natural e decidir,
como grupo, se convergimos os dois back-ends ou se eles seguem servindo publicos
diferentes."

## 4:50 – 5:00 | Encerramento
**Tela:** slide 10.
**Fala:** "Obrigado! O link do repositorio e do video estao na descricao e no
documento entregue."

---

### Checklist de gravacao
- [ ] Backend rodando (`mvn spring-boot:run`) e testado ANTES de gravar (login, criar
      curso, recalcular risco, reagendar).
- [ ] Dashboard rodando (`npm start`) e logado como `admin` antes de gravar.
- [ ] Ter um video de "Plano B" gravado, caso a demo ao vivo falhe.
- [ ] Publicar como "Nao listado" no YouTube e testar o link em aba anonima.
- [ ] Conferir a duracao final (ate 5 minutos).
