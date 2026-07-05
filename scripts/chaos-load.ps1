$TARGET_IP = "localhost"
$url = "http://${TARGET_IP}:8080/api/payments"
$body = '{"amount": 150.0}'

Write-Host "[1/3] Simulando Sobrecarga de CPU por 5 minutos via Docker..." -ForegroundColor Green
try {
    docker run -d --rm --name staging_cpu_stress alpine sh -c "CPUS=$(nproc); for i in $(seq 1 $CPUS); do while :; do :; done &; done; sleep 300" 2>&1 | Out-Null
    Write-Host "  Estresse de CPU rodando no Docker (container: staging_cpu_stress)" -ForegroundColor Green
} catch {
    Write-Host "  Docker não disponível — pulando estresse de CPU." -ForegroundColor Red
}

Write-Host "[2/3] Iniciando Ataque de Requisicoes Simultaneas (3 rodadas)..." -ForegroundColor Green
for ($rodada = 1; $rodada -le 3; $rodada++) {
    Write-Host "  Rodada $rodada/3 — 2000 requisições..." -ForegroundColor Yellow
    $jobs = @()
    for ($i = 0; $i -lt 50; $i++) {
        $jobs += Start-Job -ScriptBlock {
            param($u, $b, $n)
            for ($j = 0; $j -lt $n; $j++) {
                try {
                    Invoke-WebRequest -Uri $u -Method Post -Body $b -ContentType "application/json" -UseBasicParsing -TimeoutSec 10 | Out-Null
                } catch {}
            }
        } -ArgumentList $url, $body, 40
    }
    $jobs | Wait-Job -Timeout 60 | Out-Null
    $jobs | Remove-Job -Force
    if ($rodada -lt 3) {
        Write-Host "  Aguardando 30s até próxima rodada..."
        Start-Sleep -Seconds 30
    }
}

Write-Host "[BONUS] Simulando Varredura Maliciosa (500 requisições)..." -ForegroundColor Green
$bonusJobs = @()
1..50 | ForEach-Object {
    $bonusJobs += Start-Job -ScriptBlock {
        param($i, $ip)
        for ($r = 0; $r -lt 10; $r++) {
            try {
                $resp = Invoke-WebRequest -Uri "http://${ip}:80/rota-invalida-ataque-$i-$r" -UseBasicParsing -TimeoutSec 5
            } catch {}
        }
    } -ArgumentList $_, $TARGET_IP
}
$bonusJobs | Wait-Job -Timeout 30 | Out-Null
$bonusJobs | Remove-Job -Force

docker rm -f staging_cpu_stress 2>$null

Write-Host "[CAOS FINALIZADO] Verifique os graficos no Grafana e alertas no Slack!" -ForegroundColor Red
