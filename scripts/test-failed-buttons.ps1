# ================================================================
# 🦊 TEST FAILED BUTTONS INDIVIDUALLY
# ================================================================

Write-Host "Testing failed buttons individually..." -ForegroundColor Cyan

$tests = @(
    @{Name = "Processes"; Command = "List top processes"; Endpoint = "/api/kernel"},
    @{Name = "Open Chrome"; Command = "Open Chrome"; Endpoint = "/api/workers/app"},
    @{Name = "Open Code"; Command = "Open Code"; Endpoint = "/api/workers/app"},
    @{Name = "Clean Code"; Command = "Clean code"; Endpoint = "/api/workers/mutation"},
    @{Name = "AI News"; Command = "Deep search: AI news"; Endpoint = "/api/workers/deepsearch"}
)

foreach ($test in $tests) {
    Write-Host "`nTesting: $($test.Name)..." -ForegroundColor Yellow
    
    $body = @{task = $test.Command} | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:3001$($test.Endpoint)" -Method POST -Body $body -ContentType "application/json" -TimeoutSec 30
        
        if ($response.status -eq "success" -or $response.success) {
            Write-Host "   ✅ $($test.Name): OK" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️ $($test.Name): Returned: $($response | ConvertTo-Json)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "   ❌ $($test.Name): Failed - $($_.Exception.Message)" -ForegroundColor Red
    }
}
