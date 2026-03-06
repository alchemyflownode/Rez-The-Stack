# 🎤 Test Voice Worker
Write-Host "Testing Voice Worker..." -ForegroundColor Cyan

# Test health endpoint
$health = Invoke-RestMethod -Uri "http://localhost:3001/api/workers/voice" -Method GET
Write-Host "Voice worker: $($health.status)" -ForegroundColor Green

Write-Host "`nTo test with actual audio, use:" -ForegroundColor Yellow
Write-Host '  $form = @{ audio = Get-Item "test.wav" }' -ForegroundColor Gray
Write-Host '  Invoke-RestMethod -Uri "http://localhost:3001/api/workers/voice" -Method POST -Form $form' -ForegroundColor Gray
