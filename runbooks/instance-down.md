# Runbook: InstanceDown

**Severidade:** Critical

## Descrição

O Prometheus não consegue fazer scrape de um ou mais targets por mais de 1 minuto. O serviço pode estar fora do ar.

## Passos de Diagnóstico

1. Verificar se o container está rodando:
   ```bash
   docker ps --filter name=staging_
   ```

2. Verificar logs do container:
   ```bash
   docker logs <nome_do_container> --tail 50
   ```

3. Verificar se o container está sem rede:
   ```bash
   docker network inspect monitoring-stack_staging_net
   ```

## Resolução

1. **Container parado**: reiniciar o serviço
   ```bash
   docker compose up -d <serviço>
   ```

2. **Erro de configuração**: verificar se o endpoint de métricas mudou no `prometheus.yml`

3. **Rede corrompida**: recriar a stack
   ```bash
   docker compose down && docker compose up -d
   ```

## Contato

Time de Infraestrutura — Slack: #infra-alertas
