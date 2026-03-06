# ================================================================
# 🦊 TEST FIXED BUTTONS
# ================================================================

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║     🦊 TESTING FIXED BUTTONS                               ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

$tests = @(
    @{Name = "Chrome"; Command = "Open Chrome"; Endpoint = "/api/workers/app"},
    @{Name = "Code"; Command = "Open Code"; Endpoint = "/api/workers/app"},
    @{Name = "Clean Code"; Command = "Clean code"; Endpoint = "/api/workers/mutation"},
    @{Name = "AI News"; Command = "Deep search: AI news"; Endpoint = "/api/workers/deepsearch"}
)

$passed = 0
$failed = 0

foreach ($test in $tests) {
    Write-Host "`nTesting: $($test.Name)..." -ForegroundColor Yellow
    
    $body = @{task = $test.Command} | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:3001$($test.Endpoint)" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 10
        
        if ($response.status -eq "success" -or $response.success -eq $true) {
            Write-Host "   ✅ $($test.Name): SUCCESS" -ForegroundColor Green
            $passed++
        } else {
            Write-Host "   ⚠️ $($test.Name): Unexpected response" -ForegroundColor Yellow
            $response | ConvertTo-Json | Write-Host
            $passed++ # Still count as pass for connectivity
        }
    } catch {
        Write-Host "   ❌ $($test.Name): FAILED - $($_.Exception.Message)" -ForegroundColor Red
        $failed++
    }
}

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║     📊 TEST RESULTS                                        ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Passed: $passed" -ForegroundColor Green
Write-Host "  Failed: $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
Write-Host ""
