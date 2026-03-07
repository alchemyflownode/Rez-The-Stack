# test-vision-voice.ps1
Write-Host "🧪 Testing Vision & Voice Workers" -ForegroundColor Cyan

$baseUrl = "http://localhost:8001/kernel/stream"

# Test Vision
Write-Host "`n👁️ Testing Vision Worker..." -ForegroundColor Yellow
$body = @{ task = "describe screen"; worker = "vision" } | ConvertTo-Json
try {
    $response = Invoke-RestMethod -Uri $baseUrl -Method Post -Body $body -ContentType "application/json"
    Write-Host "✅ Vision OK" -ForegroundColor Green
} catch {
    Write-Host "❌ Vision Failed: $_" -ForegroundColor Red
}

# Test Voice (skipped by default - uncomment to test with microphone)
# Write-Host "`n🎤 Testing Voice Worker (will listen for 3 seconds)..." -ForegroundColor Yellow
# $body = @{ task = "listen 3"; worker = "voice" } | ConvertTo-Json
# try {
#     $response = Invoke-RestMethod -Uri $baseUrl -Method Post -Body $body -ContentType "application/json"
#     Write-Host "✅ Voice OK" -ForegroundColor Green
# } catch {
#     Write-Host "❌ Voice Failed: $_" -ForegroundColor Red
# }
