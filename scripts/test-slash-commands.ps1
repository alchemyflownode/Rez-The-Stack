# ===================================================
# 🏛️ TEST SLASH COMMANDS
# ===================================================

Write-Host "Testing slash commands..." -ForegroundColor Cyan

$commands = @("/check_system", "/list_files", "/clear_chat", "/help")

foreach ($cmd in $commands) {
    Write-Host "`n🔍 Testing: $cmd" -ForegroundColor Yellow
    $body = @{ task = $cmd } | ConvertTo-Json
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8002/kernel/stream" -Method Post -Body $body -ContentType "application/json"
        Write-Host "✅ Response received" -ForegroundColor Green
        $response
    } catch {
        Write-Host "❌ Failed: $_" -ForegroundColor Red
    }
    Start-Sleep -Seconds 1
}
