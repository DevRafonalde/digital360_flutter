# Roteiro do vídeo — Atividade 4 (Enterprise Challenge — Leroy Merlin)

Duração-alvo: **até 5 minutos**. Publicar no YouTube como **"Não listado"**.
Regra da atividade: pelo menos **3 minutos** devem ser demonstração funcional real —
o resto (contexto, valor, conclusão, equipe) cabe nos ~2 minutos restantes.

Este vídeo **não é uma tour de telas**. Cada corte de demo precisa vir acompanhado de
uma frase de valor ("isso resolve X", "isso importa porque Y") — é isso que separa um
pitch de produto de uma apresentação de funcionalidades soltas.

**Plano B**: grave também uma versão de tela cheia sem áudio ao vivo (só a navegação),
guardada à parte. Se a demo ao vivo falhar na hora de gravar o take final, corta pra essa
gravação de apoio e narra por cima depois.

---

## 0:00 – 0:35 | Abertura — o problema e o valor
**Tela:** slide 1 (capa) → slide 2 (o problema).
**Fala:**
"Olá! Somos o grupo do Smart HAS — Digital 360, projeto do Enterprise Challenge com a
Leroy Merlin. Milhões de idosos e pessoas com baixa escolaridade não conseguem acessar
serviços públicos essenciais — e quando conseguem, não têm como saber se aquilo que
pediram realmente chegou até eles. É exatamente essa lacuna, entre inclusão digital e
confiabilidade de entrega, que o Digital 360 com a AI Logistics Extension resolve."

## 0:35 – 0:55 | O que vamos mostrar
**Tela:** slide 3 (visão geral do produto).
**Fala:**
"Hoje o produto está completo dentro do escopo que definimos: um app Flutter para o
cidadão, um painel administrativo em Angular para quem opera a logística, e dois
backends reais — Python e Java — sustentando tudo. Vamos mostrar os dois lados
funcionando de ponta a ponta."

## 0:55 – 2:35 | DEMO 1 — App Flutter (jornada do cidadão) — ~1min40
**Tela:** app Flutter rodando (emulador ou Chrome).
**Roteiro de cliques:**
1. Login → tela Início: mostrar o painel de jornada (progresso, próximo passo sugerido).
   *Fala: "O cidadão entra e já vê onde está na jornada de inclusão — não é só uma lista
   de telas, é um acompanhamento guiado."*
2. Abrir **Logística** → lista de pedidos monitorados pela AI Logistics Extension.
   *Fala: "Aqui está o coração da extensão: cada pedido — seja uma entrega de produto ou
   uma solicitação de serviço — é monitorado como se fosse uma entrega logística real."*
3. Abrir o pedido **atrasado** → tocar **Recalcular risco**.
   *Fala: "O motor de risco analisa histórico de atrasos, distância, clima em tempo real
   via Open-Meteo, e devolve um nível de risco — aqui, CRÍTICO — com uma recomendação
   clara de ação."*
4. Tocar **Reagendar entrega**.
   *Fala: "E o cidadão já sai daqui com uma solução, não só com um alerta."*
5. Abrir **Assistente de IA** → perguntar algo tipo "minha entrega pode atrasar?".
   *Fala: "O assistente responde combinando IA generativa com uma base de conhecimento
   curada — importante pra não inventar informação sobre serviço público."*

## 2:35 – 4:05 | DEMO 2 — Painel administrativo (visão da operação) — ~1min30
**Tela:** dashboard Angular (`localhost:4200`), backend Java rodando.
**Roteiro de cliques:**
1. Login como admin → Home: KPIs agregados (cursos, serviços, pedidos monitorados,
   pedidos atrasados).
   *Fala: "Do outro lado, a equipe de operação — pensando na Leroy Merlin — enxerga o
   mesmo ecossistema de um jeito diferente: números agregados, visão de gestão."*
2. Abrir **Pedidos** → mostrar a mesma lista de pedidos (agora sob o backend Java).
   *Fala: "É a mesma camada de AI Logistics, mas exposta por um backend Java com Spring
   Boot, com autenticação JWT e permissões por perfil — só administrador altera o
   catálogo de pedidos, qualquer usuário autenticado consulta."*
3. Recalcular risco de um pedido pelo painel, reagendar.
   *Fala: "A operação consegue agir diretamente por aqui — recalcular risco, reagendar —
   sem precisar abrir o app do cidadão."*
4. Passar rapidamente por **Tendências** e **Gamificação**.
   *Fala: "E o painel também expõe a camada de inteligência: detecção de picos de
   demanda por categoria, e o engajamento dos usuários nas trilhas."*

## 4:05 – 4:30 | Produto concluído
**Tela:** slide com o checklist do que está pronto.
**Fala:**
"Isso que vocês acabaram de ver é o produto que estamos entregando — não um protótipo
em construção. O escopo que definimos, cidadão + operação + AI Logistics, está completo
e funcionando de ponta a ponta. O que fica como próximo passo — evoluir o motor de risco
para machine learning com dados reais de uso — é uma evolução consciente de escopo, não
uma pendência do que prometemos entregar agora."

## 4:30 – 4:50 | Conclusão
**Tela:** slide de fechamento com a proposta de valor.
**Fala:**
"Pra Leroy Merlin, isso significa uma forma de levar a mesma confiabilidade de uma
entrega logística de qualidade pra jornada de inclusão digital de milhões de pessoas —
transformando um problema social também em um canal de relacionamento pós-venda
acessível. É isso que torna essa solução relevante como produto, não só como projeto
acadêmico."

## 4:50 – 5:00 | Equipe e decisão do NEXT
**Tela:** slide da equipe (foto, nome completo, RM de cada um).
**Fala:**
"Somos [nomes completos + RM de cada integrante]. Sobre o NEXT 2026: como grupo,
decidimos não expor o projeto nesta edição. Obrigado!"

---

## Checklist antes de gravar
- [ ] Resetar dados de demo do backend Java (apagar `backend-java/data/`, subir de novo)
      para o pedido de exemplo estar `ATRASADO` de novo.
- [ ] Testar o fluxo inteiro (app + dashboard) uma vez sem gravar, cronometrando.
- [ ] Ter a gravação de "Plano B" pronta e salva antes de gravar o take final.
- [ ] Confirmar com o grupo os nomes completos + RM na ordem que vão aparecer na fala.
- [ ] Publicar "Não listado" no YouTube e testar o link em aba anônima.
- [ ] Conferir duração final (até 5 minutos).
