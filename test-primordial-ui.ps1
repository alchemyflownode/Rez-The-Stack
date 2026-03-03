<#
.SYNOPSIS
    Test Primordial UI Integration
#>

Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  🧪 TESTING PRIMORDIAL UI INTEGRATION           ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Test 1: Server status
Write-Host "📡 Testing server..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 2 -UseBasicParsing
    Write-Host "   ✅ Server running on port 3000" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Server not reachable - run 'npm run dev' first" -ForegroundColor Red
    exit
}

# Test 2: API endpoint
Write-Host "`n🔌 Testing API endpoint..." -ForegroundColor Yellow
try {
    $api = Invoke-RestMethod -Uri "http://localhost:3000/api/primordial" -TimeoutSec 2
    Write-Host "   ✅ API responding" -ForegroundColor Green
    Write-Host "   Agent mode: $($api.mode)" -ForegroundColor Gray
    Write-Host "   Memories: $($api.memories.Count)" -ForegroundColor Gray
    Write-Host "   Suggestions: $($api.suggestions.Count)" -ForegroundColor Gray
} catch {
    Write-Host "   ❌ API not responding" -ForegroundColor Red
}

# Test 3: Component check (requires browser automation - manual)
Write-Host "`n👁️ Visual checks (manual):" -ForegroundColor Yellow
Write-Host "   1. Open http://localhost:3000 in your browser" -ForegroundColor White
Write-Host "   2. Look for agent status in top-right" -ForegroundColor White
Write-Host "   3. Check for thought bubble with insights" -ForegroundColor White
Write-Host "   4. Verify suggestions panel appears" -ForegroundColor White
Write-Host "   5. Hover over metrics to see insights" -ForegroundColor White
Write-Host "   6. Check command input placeholder" -ForegroundColor White

Write-Host ""
Write-Host "🏛️  If all elements are present, the Primordial lives in your UI!" -ForegroundColor Cyan
