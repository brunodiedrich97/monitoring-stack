$TARGET_IP = "localhost"
$url = "http://${TARGET_IP}:8080/api/payments"
$body = '{"amount": 150.0}'

Write-Host "[1/3] Simulando Sobrecarga de CPU por 45 segundos..." -ForegroundColor Green
$cpuJob = Start-Job -ScriptBlock {
    $end = (Get-Date).AddSeconds(45)
    while ((Get-Date) -lt $end) { }
}

Write-Host "[2/3] Iniciando Ataque de Requisicoes Simultaneas (HTTP) na API de Pagamentos..." -ForegroundColor Green
$jobs = @()
$concurrency = 50
$batchSize = 100
for ($i = 0; $i -lt $concurrency; $i++) {
    $jobs += Start-Job -ScriptBlock {
        param($u, $b, $n)
        for ($j = 0; $j -lt $n; $j++) {
            try {
                Invoke-WebRequest -Uri $u -Method Post -Body $b -ContentType "application/json" -UseBasicParsing -TimeoutSec 10 | Out-Null
            } catch {}
        }
    } -ArgumentList $url, $body, $batchSize
}
$jobs | Wait-Job -Timeout 120 | Out-Null
$jobs | Remove-Job -Force

Write-Host "[BONUS] Simulando Varredura Maliciosa (Anomalia de Seguranca)..." -ForegroundColor Green
1..50 | ForEach-Object {
    try {
        $resp = Invoke-WebRequest -Uri "http://${TARGET_IP}:80/rota-invalida-ataque-$_" -UseBasicParsing -TimeoutSec 5
        Write-Host $resp.StatusCode -NoNewline
    } catch {
        Write-Host $_.Exception.Response.StatusCode.value__ -NoNewline
    }
}
Write-Host ""

$cpuJob | Stop-Job | Remove-Job

Write-Host "[CAOS FINALIZADO] Verifique os graficos no Grafana e alertas no Slack!" -ForegroundColor Red