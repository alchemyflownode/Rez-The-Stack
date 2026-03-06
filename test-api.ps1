# test-api.ps1
Write-Host "🏛️ Testing REZ HIVE API..." -ForegroundColor Cyan

# Test status endpoint
Write-Host "`n📡 Testing status endpoint..." -ForegroundColor Yellow
try {
    $status = Invoke-RestMethod -Uri "http://localhost:8001/api/status" -ErrorAction Stop
    Write-Host "   ✅ Status: OK" -ForegroundColor Green
    $status | ConvertTo-Json
} catch {
    Write-Host "   ❌ Status failed: $_" -ForegroundColor Red
}

# Test kernel endpoint
Write-Host "`n🧠 Testing kernel endpoint..." -ForegroundColor Yellow
$body = @{
    task = "Hello"
    worker = "brain"
    model = "llama3.2:latest"
    confirmed = $false
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8001/kernel/stream" `
        -Method Post `
        -Body $body `
        -ContentType "application/json" `
        -ErrorAction Stop
    Write-Host "   ✅ Kernel responded" -ForegroundColor Green
    $response | ConvertTo-Json
} catch {
    Write-Host "   ❌ Kernel test failed: $_" -ForegroundColor Red
}

# Test compatibility endpoint
Write-Host "`n🔄 Testing compatibility endpoint..." -ForegroundColor Yellow
try {
    $response2 = Invoke-RestMethod -Uri "http://localhost:8001/api/kernel" `
        -Method Post `
        -Body $body `
        -ContentType "application/json" `
        -ErrorAction Stop
    Write-Host "   ✅ Compatibility endpoint working" -ForegroundColor Green
    $response2 | ConvertTo-Json
} catch {
    Write-Host "   ❌ Compatibility test failed: $_" -ForegroundColor Red
}

Write-Host "`n✅ API tests complete" -ForegroundColor Green
