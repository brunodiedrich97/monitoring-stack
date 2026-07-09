# Runbook: HighInvalidRequestRate

**Severidade:** Warning

## Descrição

Mais de 10 requisições inválidas/s detectadas na API nos últimos 15 segundos. Requisições a rotas inexistentes geralmente indicam varredura automatizada de endpoints (scanning), tentativa de exploração de vulnerabilidades ou ataques de força bruta.

## Passos de Diagnóstico

1. Verificar a origem das requisições inválidas:
   ```bash
   docker logs staging_payment_api --tail 50
   ```

2. Identificar as rotas sendo varridas:
   ```bash
   docker logs staging_payment_api 2>&1 | grep "HTTP_404" | head -20
   ```

3. Verificar métrica no Prometheus:
   - Query: `rate(payment_invalid_requests_total[1m])`
   - Query detalhada: `topk(10, sum by(path) (rate(payment_invalid_requests_total[1m])))`

4. Verificar logs no Loki pelo Grafana:
   - Expressão: `{job="docker-logs"} |= "invalid_route"`

## Resolução

1. **Script de caos rodando**: aguardar a finalização (teste intencional)

2. **Varredura real**: identificar o IP de origem nos logs e bloquear via Nginx ou firewall

3. **Bloqueio preventivo no Nginx**:
   ```nginx
   location / {
       deny <IP_ORIGEM>;
   }
   ```

4. **Rate limiting no Nginx** (se recorrente):
   ```nginx
   limit_req_zone $binary_remote_addr zone=scan:10m rate=5r/s;
   limit_req zone=scan burst=10;
   ```

## Contato

Time de Segurança — Slack: #seguranca-alertas
