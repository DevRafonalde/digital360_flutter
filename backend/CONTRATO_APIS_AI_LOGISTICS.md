# Contrato de APIs - AI Logistics Extension

## GET /pedidos
Retorna pedidos monitorados pela camada logistica.

Campos principais:
- id
- codigoPedido
- produto
- tipoProduto
- regiaoEntrega
- distanciaKm
- prazoPrometido
- statusAtual
- parceiroLogistico
- estoqueDisponivel
- historicoAtrasos
- reagendamentos

## GET /pedidos/{id}/entrega
Retorna o detalhe logistico de um pedido.

## POST /entregas/{id}/recalcular-risco
Recalcula o score de risco da entrega.

Resposta:
```json
{
  "pedidoId": 2,
  "riscoScore": 78,
  "riscoNivel": "ALTO",
  "recomendacao": "Acionar suporte logistico e oferecer reagendamento proativo",
  "mensagemCliente": "Detectamos fatores que podem afetar a janela prometida."
}
```

## POST /assistente-logistico/pergunta
Entrada:
```json
{
  "pedidoId": 2,
  "pergunta": "Minha entrega pode atrasar?"
}
```

Saida:
```json
{
  "resposta": "O pedido esta com risco alto. A recomendacao e acionar suporte logistico antes do prazo.",
  "acaoRecomendada": "REAGENDAR"
}
```

## POST /feedback-entrega
Registra avaliacao do cliente apos entrega ou atendimento.
