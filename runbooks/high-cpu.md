# Runbook: HostHighCpuLoad

**Severidade:** Warning

## Descrição

O uso de CPU do host (node-exporter) ultrapassou 85% por mais de 30 segundos. Isso pode indicar um processo consumindo recursos anormalmente.

## Passos de Diagnóstico

1. Verificar quais containers estão usando mais CPU:
   ```bash
   docker stats --no-stream
   ```

2. Identificar processos no host:
   ```bash
   top -o %CPU
   ```

3. No ambiente Docker Desktop (macOS/Windows), verificar o Activity Monitor/Gerenciador de Tarefas da VM

## Resolução

1. **Container específico com pico**: reiniciar o container
   ```bash
   docker compose restart <serviço>
   ```

2. **Script de caos rodando**: aguardar a finalização (teste intencional)

3. **Vazamento de recurso**: verificar logs do container suspeito
   ```bash
   docker logs <container_id> --tail 100
   ```

4. **Carga legítima**: se for esperado, ajustar o threshold do alerta ou aumentar recursos da VM Docker

## Contato

Time de Infraestrutura — Slack: #infra-alertas
