# Runbook: HighRequestRate

**Severidade:** Warning

## Descrição

O volume de requisições no Nginx ultrapassou 100 req/s nos últimos 15 segundos. Pode indicar um ataque de varredura, DoS ou pico legítimo de tráfego.

## Passos de Diagnóstico

1. Verificar logs do Nginx:
   ```bash
   docker logs staging_nginx --tail 50
   ```

2. Identificar padrão suspeito nos logs:
   ```bash
   docker logs staging_nginx 2>&1 | grep -E "(404|400)" | head -20
   ```

3. Verificar métricas no Prometheus:
   - Query: `rate(nginx_http_requests_total[1m])`

4. Testar rotas inválidas manualmente:
   ```bash
   curl -v http://localhost:80/rota-aleatoria
   ```

## Resolução

1. **Script de caos rodando**: aguardar a finalização (teste intencional)

2. **Ataque de varredura**: verificar origem nos logs do Nginx e bloquear via iptables/firewall se necessário

3. **Pico legítimo**: se for tráfego esperado, dimensionar os recursos ou ajustar o threshold do alerta

## Contato

Time de Segurança — Slack: #seguranca-alertas
