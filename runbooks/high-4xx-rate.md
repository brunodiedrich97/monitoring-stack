# Runbook: High4xxRate

**Severidade:** Warning

## Descrição

A taxa de erros 4xx na API de Pagamentos ultrapassou 15% nos últimos 30 segundos. Isso pode indicar tentativas de fraude (cartões declinados em massa), ataques de força bruta ou problemas de integração com sistemas externos.

## Passos de Diagnóstico

1. Verificar os logs da API para identificar padrão de erros 400:
   ```bash
   docker logs staging_payment_api --tail 50
   ```

2. Contar ocorrências de erro 400:
   ```bash
   docker logs staging_payment_api 2>&1 | grep "400" | wc -l
   ```

3. Verificar métrica no Prometheus:
   - Query: `sum by(status) (rate(payment_requests_total[1m]))`
   - Query taxa 4xx: `(sum(rate(payment_requests_total{status=~"4.."}[1m])) / sum(rate(payment_requests_total[1m]))) * 100`

4. Verificar transações DECLINED no banco:
   ```bash
   docker exec staging_postgres psql -U postgres -d payment_db -c "SELECT count(*), status FROM payment_transactions GROUP BY status;"
   ```

## Resolução

1. **Script de caos rodando**: aguardar a finalização (teste intencional)

2. **Falha de integração**: verificar conectividade com operadoras de cartão (simulado na API)

3. **Fraude/abuso**: identificar IP de origem nos logs e aplicar rate limiting no Nginx

4. **Ajuste de threshold**: se o pico for esperado (ex: promoção), reavaliar o limiar de 15%

## Contato

Time de Segurança — Slack: #seguranca-alertas
Time de Desenvolvimento — Slack: #dev-alertas
