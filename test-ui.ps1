# test-ui.ps1
Write-Host "🧪 Testing REZ HIVE endpoints..." -ForegroundColor Cyan

# Test status
try {
    $status = Invoke-RestMethod -Uri "http://localhost:8001/status" -ErrorAction Stop
    Write-Host "✅ Kernel status: OK" -ForegroundColor Green
    $status | ConvertTo-Json
} catch {
    Write-Host "❌ Kernel not responding" -ForegroundColor Red
}

Write-Host ""
Write-Host "📊 Open these URLs:" -ForegroundColor Yellow
Write-Host "   • Main UI: http://localhost:3001" -ForegroundColor White
Write-Host "   • Chat UI: http://localhost:3001/rez-hive.html" -ForegroundColor White
