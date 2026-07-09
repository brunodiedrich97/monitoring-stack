#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

TARGET_IP="localhost"

echo -e "${GREEN}[1/4] Verificando ferramentas de carga...${NC}"
if ! command -v ab &> /dev/null; then
    if command -v apt-get &> /dev/null; then
        sudo apt-get install -y apache2-utils
    fi
fi

echo -e "\n${GREEN}[2/4] Simulando Sobrecarga de CPU por 5 minutos...${NC}"
docker run -d --rm --name staging_cpu_stress alpine sh -c '
  CPUS=$(nproc)
  for i in $(seq 1 $CPUS); do
    while :; do :; done &
  done
  sleep 300
' > /dev/null
echo -e "${YELLOW}Estresse de CPU rodando (container: staging_cpu_stress)${NC}"

echo -e "\n${GREEN}[3/4] Ataque de Requisicoes via Nginx (porta 80) — 3 rodadas...${NC}"
echo '{"amount": 150.0}' > /tmp/payment-data.json

for rodada in 1 2 3; do
    echo -e "${YELLOW}Rodada $rodada/3 — 2000 requisições via Nginx...${NC}"
    ab -n 2000 -c 20 -p /tmp/payment-data.json -T application/json http://${TARGET_IP}:80/api/payments 2>&1 | tail -3
    echo -e "${YELLOW}Rodada $rodada concluída, aguardando 30s...${NC}"
    sleep 30
done

rm -f /tmp/payment-data.json

echo -e "\n${GREEN}[4/4] Varredura Maliciosa — 1500 requisicoes a rotas invalidas...${NC}"
echo -e "${YELLOW}Disparando 3 lotes paralelos de 500 reqs para /rota-ataque...${NC}"
ab -n 500 -c 50 http://${TARGET_IP}:80/rota-ataque > /dev/null 2>&1 &
ab -n 500 -c 50 http://${TARGET_IP}:80/rota-ataque > /dev/null 2>&1 &
ab -n 500 -c 50 http://${TARGET_IP}:80/rota-ataque > /dev/null 2>&1 &
wait
echo -e "${YELLOW}Varredura concluída (1500 reqs para rota inválida).${NC}"

docker rm -f staging_cpu_stress 2>/dev/null

echo -e "\n${RED}[CAOS FINALIZADO]${NC} Verifique os graficos no Grafana e alertas no Slack!"
echo -e "  Dashboard:  ${GREEN}http://localhost:3000${NC} (admin/admin)"
echo -e "  Prometheus: ${GREEN}http://localhost:9090${NC}"
