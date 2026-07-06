# Runbook: HighHttp5xxRate

**Severidade:** Critical

## Descrição

A taxa de erros HTTP 5xx na API de Pagamentos ultrapassou 5% nos últimos 30 segundos. A aplicação pode estar com falhas internas.

## Passos de Diagnóstico

1. Verificar logs da API:
   ```bash
   docker logs staging_payment_api --tail 50
   ```

2. Testar a API manualmente:
   ```bash
   curl -v -X POST http://localhost:8080/api/payments \
     -H "Content-Type: application/json" \
     -d '{"amount": 100.0}'
   ```

3. Verificar métricas de erro no Prometheus:
   - Query: `payment_requests_total{status=~"5.."}`

4. Verificar conectividade com o banco:
   ```bash
   docker logs staging_payment_api | grep -i "error\|exception\|timeout"
   ```

## Resolução

1. **Erro transitório (caos)**: aguardar a normalização (5% de erro é intencional)

2. **Banco indisponível**: verificar PostgreSQL
   ```bash
   docker compose restart postgres
   ```

3. **Bug na aplicação**: verificar os logs e reiniciar o serviço
   ```bash
   docker compose logs payment-api --tail 100
   docker compose restart payment-api
   ```

## Contato

Time de Desenvolvimento — Slack: #dev-alertas
