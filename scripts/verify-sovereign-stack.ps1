# ================================================================
# 🚦 SOVEREIGN STACK VERIFICATION
# ================================================================

Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  🚦 SOVEREIGN STACK VERIFICATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Magenta

 $pass = 0
 $total = 5

# 1. CHECK CRITICAL FILES
Write-Host "`n[1/5] File Integrity..." -ForegroundColor White
if ((Test-Path "src\app\api\kernel\route.ts") -and (Test-Path "src\lib\crystalline-engine.ts")) {
    Write-Host "   ✅ Brain Files Present" -ForegroundColor Green; $pass++
} else { Write-Host "   ❌ Brain Files Missing" -ForegroundColor Red }

# 2. CHECK PYTHON WORKERS
Write-Host "`n[2/5] Python Workers..." -ForegroundColor White
if ((Test-Path "src\workers\system_agent.py") -and (Test-Path "src\workers\search_harvester.py")) {
    Write-Host "   ✅ Hands (Workers) Present" -ForegroundColor Green; $pass++
} else { Write-Host "   ❌ Workers Missing" -ForegroundColor Red }

# 3. CHECK GOVERNANCE
Write-Host "`n[3/5] Governance Layer..." -ForegroundColor White
if ((Test-Path "constitution.json") -and (Test-Path "rez.config.json")) {
    Write-Host "   ✅ Soul (Constitution) Present" -ForegroundColor Green; $pass++
} else { Write-Host "   ❌ Constitution Missing" -ForegroundColor Red }

# 4. CHECK LIVE API (Requires Running Server)
Write-Host "`n[4/5] Server Connectivity..." -ForegroundColor White
try {
    $res = Invoke-RestMethod -Uri "http://localhost:3001/api/kernel" -Method Get -TimeoutSec 2
    if ($res.status -eq "sovereign") {
        Write-Host "   ✅ Kernel Online (Status: Sovereign)" -ForegroundColor Green; $pass++
    } else { Write-Host "   ⚠️ Kernel Online (Degraded)" -ForegroundColor Yellow }
} catch {
    Write-Host "   ❌ Server Offline (Run .\rez-control.bat)" -ForegroundColor Red
}

# 5. CHECK HARDWARE MONITOR (Real Stats)
Write-Host "`n[5/5] Hardware Monitoring..." -ForegroundColor White
try {
    $res = Invoke-RestMethod -Uri "http://localhost:3001/api/system/snapshot" -TimeoutSec 2
    if ($res.cpu.percent -ge 0) {
        Write-Host "   ✅ Hardware Online (CPU: $($res.cpu.percent)%)" -ForegroundColor Green; $pass++
    } else { Write-Host "   ⚠️ Hardware Returning Zeros" -ForegroundColor Yellow }
} catch {
    Write-Host "   ❌ System Snapshot Failed" -ForegroundColor Red
}

# FINAL VERDICT
Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  🏆 RESULT: $pass / $total PASSED" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Magenta

if ($pass -eq $total) {
    Write-Host "`n🟢 ALL SYSTEMS GO" -ForegroundColor Green
    Write-Host "The Sovereign Stack is stable." -ForegroundColor White
} else {
    Write-Host "`n🔴 SYSTEMS REQUIRE ATTENTION" -ForegroundColor Red
}
