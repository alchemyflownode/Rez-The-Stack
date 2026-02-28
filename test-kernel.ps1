# test-kernel.ps1
Write-Host "🧪 Testing Cognitive Kernel..." -ForegroundColor Cyan

# Test 1: Basic health check
try {
    $response = Invoke-RestMethod -Uri "http://localhost:3000/api/kernel" -Method GET -ErrorAction Stop
    Write-Host "✅ GET /api/kernel - OK" -ForegroundColor Green
} catch {
    Write-Host "❌ GET /api/kernel - Failed: $_" -ForegroundColor Red
}

# Test 2: POST with task
try {
    $body = @{task="List files in current directory"} | ConvertTo-Json
    $response = Invoke-RestMethod -Uri "http://localhost:3000/api/kernel" -Method POST -Body $body -ContentType "application/json" -ErrorAction Stop
    Write-Host "✅ POST /api/kernel - OK" -ForegroundColor Green
    Write-Host "   Queen decided: $($response.queenDecision.worker) - $($response.queenDecision.reason)" -ForegroundColor Yellow
} catch {
    Write-Host "❌ POST /api/kernel - Failed: $_" -ForegroundColor Red
}

# Test 3: App worker directly
try {
    $body = @{action="launch"; app="notepad"} | ConvertTo-Json
    $response = Invoke-RestMethod -Uri "http://localhost:3000/api/workers/app" -Method POST -Body $body -ContentType "application/json" -ErrorAction Stop
    Write-Host "✅ App worker - OK" -ForegroundColor Green
} catch {
    Write-Host "❌ App worker - Failed: $_" -ForegroundColor Red
}

# Test 4: File worker directly
try {
    $body = @{action="list"; path="."} | ConvertTo-Json
    $response = Invoke-RestMethod -Uri "http://localhost:3000/api/workers/file" -Method POST -Body $body -ContentType "application/json" -ErrorAction Stop
    Write-Host "✅ File worker - OK" -ForegroundColor Green
} catch {
    Write-Host "❌ File worker - Failed: $_" -ForegroundColor Red
}

# Test 5: MCP worker
try {
    $body = @{tool="list_tools"} | ConvertTo-Json
    $response = Invoke-RestMethod -Uri "http://localhost:3000/api/workers/mcp" -Method POST -Body $body -ContentType "application/json" -ErrorAction Stop
    Write-Host "✅ MCP worker - OK" -ForegroundColor Green
} catch {
    Write-Host "❌ MCP worker - Failed: $_" -ForegroundColor Red
}

Write-Host "`n✨ Testing complete!" -ForegroundColor Magenta
