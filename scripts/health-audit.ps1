# ===================================================
# 🏛️ REZ HIVE - COMPREHENSIVE HEALTH AUDIT
# ===================================================

$services = @(
    @{Name="Kernel"; Port=8002; Url="http://localhost:8002/health"},
    @{Name="ChromaDB"; Port=8000; Url="http://localhost:8000/api/v2/heartbeat"},
    @{Name="Frontend"; Port=3001; Url="http://localhost:3001"},
    @{Name="Ollama"; Port=11434; Url="http://localhost:11434/api/version"}
)

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  🏛️  REZ HIVE - COMPREHENSIVE HEALTH AUDIT                 ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

function Test-Port {
    param($Port)
    $tcp = New-Object System.Net.Sockets.TcpClient
    try {
        $tcp.Connect("localhost", $Port)
        $tcp.Close()
        return $true
    } catch {
        return $false
    }
}

# Check services
foreach ($service in $services) {
    Write-Host "🔍 Checking $($service.Name)..." -ForegroundColor Yellow
    $portOpen = Test-Port -Port $service.Port
    if ($portOpen) {
        Write-Host "  ✅ Port $($service.Port): OPEN" -ForegroundColor Green
        
        # Test HTTP endpoint
        try {
            $response = Invoke-WebRequest -Uri $service.Url -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
            Write-Host "  ✅ HTTP: OK (Status $($response.StatusCode))" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠️ HTTP: Failed - $_" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ❌ Port $($service.Port): CLOSED" -ForegroundColor Red
    }
    Write-Host ""
}

# Check Workers
Write-Host "🔍 Checking Workers via API..." -ForegroundColor Yellow
try {
    $workers = Invoke-RestMethod -Uri "http://localhost:8002/workers" -Method Get -ErrorAction Stop
    Write-Host "  ✅ API: /workers responded" -ForegroundColor Green
    Write-Host "  📋 Registered Workers ($($workers.workers.Count)):" -ForegroundColor Cyan
    $workers.workers | ForEach-Object {
        $status = if ($_.status -eq "available") { "✅" } else { "❌" }
        Write-Host "     $status $($_.name): $($_.description)" -ForegroundColor Gray
    }
} catch {
    Write-Host "  ❌ API: Failed to get workers - $_" -ForegroundColor Red
}

# Check Files
Write-Host ""
Write-Host "📁 Checking Critical Files..." -ForegroundColor Yellow
$files = @(
    @{Path="backend\kernel.py"; Name="Kernel"},
    @{Path="backend\workers\brain_worker.py"; Name="Brain Worker"},
    @{Path="backend\workers\eyes_worker.py"; Name="Eyes Worker"},
    @{Path="backend\workers\hands_worker.py"; Name="Hands Worker"},
    @{Path="backend\workers\memory_worker.py"; Name="Memory Worker"},
    @{Path="backend\workers\system_worker.py"; Name="System Worker"}
)

foreach ($file in $files) {
    if (Test-Path $file.Path) {
        $size = (Get-Item $file.Path).Length / 1KB
        Write-Host "  ✅ $($file.Name): Found ($([math]::Round($size,2)) KB)" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $($file.Name): MISSING" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✅ AUDIT COMPLETE                                          ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
