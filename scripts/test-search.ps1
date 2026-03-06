# ================================================================
# 🦊 TEST REAL SEARCH
# ================================================================

Write-Host ""
Write-Host "Testing Real DuckDuckGo Search..." -ForegroundColor Cyan

$queries = @(
    "latest AI news",
    "quantum computing breakthroughs",
    "Next.js 16 features",
    "Python machine learning tutorials"
)

foreach ($query in $queries) {
    Write-Host "`n🔍 Searching: '$query'" -ForegroundColor Yellow
    
    try {
        $body = @{task = $query} | ConvertTo-Json
        $response = Invoke-RestMethod -Uri "http://localhost:3001/api/workers/deepsearch" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 15
        
        if ($response.status -eq "success") {
            Write-Host "   ✅ Found $($response.count) results" -ForegroundColor Green
            if ($response.results) {
                $response.results | Select-Object -First 2 | ForEach-Object {
                    Write-Host "      • $($_.title)" -ForegroundColor Gray
                }
            }
        } else {
            Write-Host "   ❌ Search failed: $($response.error)" -ForegroundColor Red
        }
    } catch {
        Write-Host "   ❌ Error: $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Test complete!" -ForegroundColor Cyan
