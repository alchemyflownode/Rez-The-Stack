# 🎨 Test Canvas Worker
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "Testing Canvas Worker..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Magenta

# Test simple generation
$body = @{task="Generate image of a cyberpunk samurai in rain"} | ConvertTo-Json
try {
    $result = Invoke-RestMethod -Uri "http://localhost:3001/api/workers/canvas" -Method POST -Body $body -ContentType "application/json" -TimeoutSec 60

    if ($result.status -eq 'success') {
        Write-Host "`n✅ Image generated!" -ForegroundColor Green
        Write-Host "   URL: http://localhost:3001$($result.imageUrl)" -ForegroundColor Cyan
    } else {
        Write-Host "`n❌ Failed: $($result.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "`n❌ Error: $_" -ForegroundColor Red
}
