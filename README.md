# Projeto de Monitoramento Contínuo com Múltiplas Camadas

Este projeto apresenta a implementação prática de uma solução robusta de **Continuous Monitoring (Múltiplas Camadas)** para ambiente local. A stack cobre telemetria de infraestrutura, aplicação, rede e segurança, utilizando ferramentas de mercado integradas via Docker.

## Arquitetura e Fluxo Operacional

A infraestrutura roda em um único host Docker com redes isoladas, simulando um ambiente completo de monitoramento.

![Alt Text](./images/fluxo-operacional.jpeg)

1. **Camada de Alvos (Data Sources):** O Nginx atua como proxy, direcionando chamadas para a API Python (FastAPI) que se comunica com o PostgreSQL. Cada componente possui um agente dedicado de coleta de métricas e geração de logs.
2. **Coleta e Ingestão (Scrape):** O Prometheus realiza buscas ativas (*scrape*) periódicas nos exporters através da rede interna. O Promtail monitora os arquivos de log locais e os envia continuamente para o Loki.
3. **Visualização e Alertas:** O Grafana centraliza a visualização em painéis ricos (incluindo métricas de SLO/SLA). Se alguma anomalia violar as regras pré-definidas, o Prometheus aciona o Alertmanager, que despacha uma notificação rica diretamente para o canal do Slack com o respectivo Runbook de resolução.

---

## Como Executar o Projeto

### Pré-requisitos

- **Docker** e **Docker Compose** rodando.

### Passo 1: Subir a Stack Completa

Na raiz do projeto, inicie a orquestração:

```bash
docker compose up --build -d
```

Verifique se todos os contêineres iniciaram corretamente com `docker ps`. Você deverá ver 12 serviços em execução.

### Passo 3: Validação Rápida (Smoke Test)

- **API de Pagamentos:** Acesse `http://localhost:8080/metrics` para verificar as métricas do Prometheus.
- **Prometheus:** Acesse `http://localhost:9090` -> _Status_ -> _Targets_ e verifique se os 4 alvos estão marcados como **UP**.
- **Grafana:** Acesse `http://localhost:3000` (Login: `admin` / Senha: `admin`).

---

## Simulação de Incidentes e Engenharia de Caos

Para validar a eficácia dos alertas e o comportamento dos painéis em tempo real, execute o script de estresse:

```bash
chmod +x ./scripts/chaos-load.sh
./scripts/chaos-load.sh
```

Esse script simulará alta carga de processamento de hardware, requisições massivas na API e varreduras maliciosas no proxy de borda, forçando o disparo de notificações no Slack e flutuações nos gráficos do Grafana.

---

## Componentes da Stack

| Componente | Função | Porta |
|---|---|---|
| **PostgreSQL** | Banco de dados da aplicação | `5432` |
| **Payment API** | API de pagamentos em Python (FastAPI) | `8080` |
| **Nginx** | Proxy reverso e stub status | `80` |
| **Node Exporter** | Métricas do host (CPU, memória, disco) | `9100` |
| **Nginx Exporter** | Métricas do Nginx | `9113` |
| **Postgres Exporter** | Métricas do PostgreSQL | `9187` |
| **Promtail** | Coleta e envio de logs para o Loki | `9080` |
| **Prometheus** | Armazenamento de métricas e avaliação de alertas | `9090` |
| **Loki** | Armazenamento de logs | `3100` |
| **Grafana** | Visualização em dashboards | `3000` |
| **Alertmanager** | Gerenciamento e despacho de alertas | `9093` |

## Alertas Configurados

| Alerta | Descrição | Gravidade |
|---|---|---|
| **InstanceDown** | Alvo de scrape indisponível por mais de 1 minuto | critical |
| **HostHighCpuLoad** | CPU acima de 85% por mais de 2 minutos | warning |
| **HighHttp5xxRate** | Mais de 5% de erros 5xx em 1 minuto | critical |
| **PotentialBruteForceOrScan** | Mais de 20 requisições 4xx/s detectadas | warning |
