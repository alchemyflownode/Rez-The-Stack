# ===================================================
# 🏛️ REZ HIVE - COMPLETE ENDPOINT TESTER
# Tests all workers and endpoints
# ===================================================

$baseUrl = "http://localhost:8002"
$kernelStream = "$baseUrl/kernel/stream"

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  🏛️  REZ HIVE - COMPLETE ENDPOINT TEST                     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Test 1: Health Check
Write-Host "[1/7] Testing Health Endpoint..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get
    Write-Host "  ✅ Health: OK" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Health Failed: $_" -ForegroundColor Red
}

# Test 2: List Workers
Write-Host "[2/7] Testing Workers Endpoint..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/workers" -Method Get
    Write-Host "  ✅ Workers: $($response.workers.Count) registered" -ForegroundColor Green
    $response.workers | ForEach-Object { Write-Host "     - $($_.name): $($_.description)" -ForegroundColor Gray }
} catch {
    Write-Host "  ❌ Workers Failed: $_" -ForegroundColor Red
}

# Test 3: Brain Worker
Write-Host "[3/7] Testing Brain Worker..." -ForegroundColor Yellow
$body = @{ task = "What is the capital of France?"; worker = "brain" } | ConvertTo-Json
try {
    $response = Invoke-RestMethod -Uri $kernelStream -Method Post -Body $body -ContentType "application/json"
    Write-Host "  ✅ Brain Worker: Responded" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Brain Worker Failed: $_" -ForegroundColor Red
}

# Test 4: Eyes Worker
Write-Host "[4/7] Testing Eyes Worker..." -ForegroundColor Yellow
$body = @{ task = "latest AI news"; worker = "eyes" } | ConvertTo-Json
try {
    $response = Invoke-RestMethod -Uri $kernelStream -Method Post -Body $body -ContentType "application/json"
    Write-Host "  ✅ Eyes Worker: Responded" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Eyes Worker Failed: $_" -ForegroundColor Red
}

# Test 5: Hands Worker
Write-Host "[5/7] Testing Hands Worker..." -ForegroundColor Yellow
$body = @{ task = "Create a Python function to calculate fibonacci"; worker = "hands" } | ConvertTo-Json
try {
    $response = Invoke-RestMethod -Uri $kernelStream -Method Post -Body $body -ContentType "application/json"
    Write-Host "  ✅ Hands Worker: Responded" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Hands Worker Failed: $_" -ForegroundColor Red
}

# Test 6: System Worker
Write-Host "[6/7] Testing System Worker..." -ForegroundColor Yellow
$body = @{ task = "/check_system"; worker = "system" } | ConvertTo-Json
try {
    $response = Invoke-RestMethod -Uri $kernelStream -Method Post -Body $body -ContentType "application/json"
    Write-Host "  ✅ System Worker: Responded" -ForegroundColor Green
} catch {
    Write-Host "  ❌ System Worker Failed: $_" -ForegroundColor Red
}

# Test 7: Files Worker
Write-Host "[7/7] Testing Files Worker..." -ForegroundColor Yellow
$body = @{ task = "list drives"; worker = "files" } | ConvertTo-Json
try {
    $response = Invoke-RestMethod -Uri $kernelStream -Method Post -Body $body -ContentType "application/json"
    Write-Host "  ✅ Files Worker: Responded" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Files Worker Failed: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✅ TESTING COMPLETE                                        ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
