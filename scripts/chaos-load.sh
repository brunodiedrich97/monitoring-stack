#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

TARGET_IP="localhost"

echo -e "${GREEN}[1/3] Instalando ferramentas de estresse e carga...${NC}"
sudo apt-get update -y && sudo apt-get install -y stress apache2-utils

echo -e "\n${GREEN}[2/3] Simulando Sobrecarga de CPU por 45 segundos...${NC}"
stress --cpu 2 --timeout 45s &

echo -e "\n${GREEN}[3/3] Iniciando Ataque de Requisicoes Simultaneas (HTTP)...${NC}"
ab -n 5000 -c 50 http://${TARGET_IP}:8080/metrics

echo -e "\n${GREEN}[BONUS] Simulando Varredura Maliciosa (Anomalia de Seguranca)...${NC}"
for i in {1..50}
do
   curl -s -o /dev/null -w "%{http_code}" http://${TARGET_IP}:80/rota-invalida-ataque-$i
done

echo -e "\n${RED}[CAOS FINALIZADO]${NC} Verifique os graficos no Grafana e alertas no Slack!"