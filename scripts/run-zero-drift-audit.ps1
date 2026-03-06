# run-zero-drift-audit.ps1
Write-Host "🏛️ REZ HIVE Zero-Drift Audit" -ForegroundColor Cyan
Write-Host "================================"

# 1. Check all services
Write-Host "`n📡 Checking services..." -ForegroundColor Yellow

# Ollama
$ollama = ollama list 2>$null
if ($ollama) {
    Write-Host "  ✅ Ollama running" -ForegroundColor Green
    $models = ($ollama | Select-String -Pattern "NAME" -NotMatch).Count
    Write-Host "     ($models models available)" -ForegroundColor Gray
} else {
    Write-Host "  ❌ Ollama NOT running" -ForegroundColor Red
}

# ChromaDB
try {
    $chroma = curl.exe -s http://localhost:8000/api/v1/heartbeat 2>$null
    if ($chroma) {
        Write-Host "  ✅ ChromaDB running on port 8000" -ForegroundColor Green
    } else {
        Write-Host "  ❌ ChromaDB NOT running" -ForegroundColor Red
    }
} catch {
    Write-Host "  ❌ ChromaDB NOT running" -ForegroundColor Red
}

# FastAPI
try {
    $fastapi = curl.exe -s http://localhost:8001/api/status 2>$null
    if ($fastapi) {
        Write-Host "  ✅ FastAPI running on port 8001" -ForegroundColor Green
    } else {
        Write-Host "  ❌ FastAPI NOT running" -ForegroundColor Red
    }
} catch {
    Write-Host "  ❌ FastAPI NOT running" -ForegroundColor Red
}

# SearXNG
try {
    $searxng = curl.exe -s http://localhost:8080/search?q=test&format=json 2>$null
    if ($searxng) {
        Write-Host "  ✅ SearXNG running on port 8080" -ForegroundColor Green
    } else {
        Write-Host "  ❌ SearXNG NOT running" -ForegroundColor Red
    }
} catch {
    Write-Host "  ❌ SearXNG NOT running" -ForegroundColor Red
}

# 2. Check constitutional layer
Write-Host "`n📜 Checking constitutional layer..." -ForegroundColor Yellow

if (Test-Path "backend\kernel.py") {
    $kernelContent = Get-Content "backend\kernel.py" -Raw
    if ($kernelContent -match "system_prompt.*constitutional|CONSTITUTION|You are REZ HIVE") {
        Write-Host "  ✅ Constitutional prompts active" -ForegroundColor Green
    } else {
        Write-Host "  ❌ No constitutional prompts found" -ForegroundColor Red
    }
} else {
    Write-Host "  ⚠️ kernel.py not found" -ForegroundColor Yellow
}

# 3. Check memory persistence
Write-Host "`n💾 Checking memory layer..." -ForegroundColor Yellow

if (Test-Path "chroma_data") {
    Write-Host "  ✅ ChromaDB data directory exists" -ForegroundColor Green
} else {
    Write-Host "  ⚠️ ChromaDB data not found" -ForegroundColor Yellow
}

# 4. Generate report
Write-Host "`n📊 Generating audit report..." -ForegroundColor Yellow

$report = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    services = @{
        ollama = $ollama -ne $null
        chroma = $chroma -ne $null
        fastapi = $fastapi -ne $null
        searxng = $searxng -ne $null
    }
    constitutional = $kernelContent -match "CONSTITUTION|You are REZ HIVE"
    models_count = if ($ollama) { ($ollama | Select-String -Pattern "NAME" -NotMatch).Count } else { 0 }
    recommendations = @()
}

# Add recommendations based on findings
if (-not $report.services.fastapi) {
    $report.recommendations += "Start FastAPI: python backend\kernel.py"
}
if (-not $report.services.chroma) {
    $report.recommendations += "Start ChromaDB: chroma run --path ./chroma_data --port 8000"
}
if ($report.models_count -eq 0) {
    $report.recommendations += "Pull models: ollama pull llama3.2"
}

$report | ConvertTo-Json | Out-File "zero-drift-audit.json"

Write-Host "✅ Audit complete! Report saved to zero-drift-audit.json" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Summary:" -ForegroundColor Cyan
Write-Host "  • Models: $($report.models_count) available"
Write-Host "  • Services: Ollama:$($report.services.ollama) Chroma:$($report.services.chroma) FastAPI:$($report.services.fastapi) SearXNG:$($report.services.searxng)"
Write-Host "  • Constitutional: $($report.constitutional)"