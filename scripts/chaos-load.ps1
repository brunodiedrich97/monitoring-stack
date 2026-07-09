$TARGET_IP = "localhost"
$url = "http://${TARGET_IP}:80/api/payments"
$body = '{"amount": 150.0}'

function timestamp { return Get-Date -Format "HH:mm:ss" }

Write-Host "$(timestamp) [1/4] Simulando Sobrecarga de CPU por 5 minutos via Docker..." -ForegroundColor Green
try {
    docker run -d --rm --name staging_cpu_stress alpine sh -c "CPUS=$(nproc); for i in $(seq 1 $CPUS); do while :; do :; done &; done; sleep 300" 2>&1 | Out-Null
    Write-Host "$(timestamp) Estresse de CPU rodando (container: staging_cpu_stress)" -ForegroundColor Yellow
} catch {
    Write-Host "$(timestamp) Docker não disponível — pulando estresse de CPU." -ForegroundColor Red
}

Write-Host "$(timestamp) [2/4] Ataque de Requisicoes via Nginx (porta 80) — 3 rodadas..." -ForegroundColor Green
for ($rodada = 1; $rodada -le 3; $rodada++) {
    Write-Host "$(timestamp) Rodada $rodada/3 — 2000 requisições..." -ForegroundColor Yellow
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
    Write-Host "$(timestamp) Rodada $rodada concluída, aguardando 30s..." -ForegroundColor Yellow
    if ($rodada -lt 3) {
        Start-Sleep -Seconds 30
    }
}

Write-Host "$(timestamp) [3/4] Varredura Maliciosa — 1500 requisicoes a rotas invalidas..." -ForegroundColor Green
$scanUrl = "http://${TARGET_IP}:80/rota-ataque"
$scanJobs = @()
1..30 | ForEach-Object {
    $scanJobs += Start-Job -ScriptBlock {
        param($u)
        for ($r = 0; $r -lt 50; $r++) {
            try {
                Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 5 | Out-Null
            } catch {}
        }
    } -ArgumentList $scanUrl
}
$scanJobs | Wait-Job -Timeout 30 | Out-Null
$scanJobs | Remove-Job -Force
Write-Host "$(timestamp) Varredura concluída (1500 reqs para rota inválida)." -ForegroundColor Yellow

docker rm -f staging_cpu_stress 2>$null

Write-Host "$(timestamp) [CAOS FINALIZADO] Verifique os graficos no Grafana e alertas no Slack!" -ForegroundColor Red
Write-Host "  Dashboard:  http://localhost:3000 (admin/admin)" -ForegroundColor Green
Write-Host "  Prometheus: http://localhost:9090" -ForegroundColor Green
