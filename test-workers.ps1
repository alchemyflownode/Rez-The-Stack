# ================================================================
# 🦊 TEST WORKER CONNECTIVITY
# ================================================================

Write-Host "Testing worker connectivity..." -ForegroundColor Cyan

$endpoints = @(
    "/api/system/snapshot",
    "/api/frontend/workers",
    "/api/heartbeat"
)

foreach ($endpoint in $endpoints) {
    Write-Host "`nTesting $endpoint..." -ForegroundColor Yellow
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3001$endpoint" -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Host "  ✅ $endpoint - OK" -ForegroundColor Green
        } else {
            Write-Host "  ❌ $endpoint - $($response.StatusCode)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ❌ $endpoint - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nTest complete!" -ForegroundColor Cyan
