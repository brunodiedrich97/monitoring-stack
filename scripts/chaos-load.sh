#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

TARGET_IP="localhost"

echo -e "${GREEN}[1/3] Verificando ferramentas de carga...${NC}"
if ! command -v ab &> /dev/null; then
    if command -v apt-get &> /dev/null; then
        sudo apt-get install -y apache2-utils
    fi
fi

echo -e "\n${GREEN}[2/3] Simulando Sobrecarga de CPU por 5 minutos...${NC}"
docker run -d --rm --name staging_cpu_stress alpine sh -c '
  CPUS=$(nproc)
  for i in $(seq 1 $CPUS); do
    while :; do :; done &
  done
  sleep 300
' > /dev/null
echo "Estresse de CPU rodando no Docker (container: staging_cpu_stress)"

echo -e "\n${GREEN}[3/3] Iniciando Ataque de Requisicoes Simultaneas (3 rodadas)...${NC}"
echo '{"amount": 150.0}' > /tmp/payment-data.json

for rodada in 1 2 3; do
    echo "Rodada $rodada/3 — 2000 requisições..."
    ab -n 2000 -c 20 -p /tmp/payment-data.json -T application/json http://${TARGET_IP}:8080/api/payments 2>&1 | tail -3
    sleep 30
done

rm -f /tmp/payment-data.json

echo -e "\n${GREEN}[BONUS] Simulando Varredura Maliciosa (500 requisições)...${NC}"
for i in $(seq 1 500); do
   curl -s -o /dev/null -w "%{http_code}" http://${TARGET_IP}:80/rota-invalida-ataque-$i &
done
wait
echo ""

docker rm -f staging_cpu_stress 2>/dev/null

echo -e "\n${RED}[CAOS FINALIZADO]${NC} Verifique os graficos no Grafana e alertas no Slack!"
