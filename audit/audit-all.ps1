# audit-all.ps1
# REZ HIVE Full System Audit Chain
# Run this to verify all "Hands" are talking to "Eyes"

param(
    [switch]$Deep,
    [switch]$Fix
)

$ErrorActionPreference = "Stop"
$results = @()

function Write-Status($message, $status, $color = "White") {
    $emoji = if ($status -eq "PASS") { "✅" } elseif ($status -eq "FAIL") { "❌" } elseif ($status -eq "WARN") { "⚠️" } else { "🔍" }
    Write-Host "$emoji $message" -ForegroundColor $color
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║           🕵️ REZ HIVE SOVEREIGN AUDIT CHAIN                  ║" -ForegroundColor Magenta
Write-Host "║           Verifying Hand-Eye-Brain Connection                ║" -ForegroundColor Magenta
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

# Test 1: Python Environment
Write-Host "[1/6] Testing Python Environment..." -ForegroundColor Cyan
try {
    $pyVersion = python --version 2>&1
    Write-Status "Python detected: $pyVersion" "PASS" "Green"
    $results += @{Test="Python"; Status="PASS"; Detail=$pyVersion}
} catch {
    Write-Status "Python not found in PATH" "FAIL" "Red"
    $results += @{Test="Python"; Status="FAIL"; Detail=$_.Exception.Message}
}

# Test 2: System Agent (PC Management Hands)
Write-Host "`n[2/6] Testing System Agent (PC Management)..." -ForegroundColor Cyan
try {
    $sysResult = python src/api/workers/system_agent.py snapshot | ConvertFrom-Json
    if ($sysResult.success) {
        Write-Status "System Agent responding - CPU: $($sysResult.cpu.percent)% | RAM: $($sysResult.memory.percent)%" "PASS" "Green"
        $results += @{Test="System Agent"; Status="PASS"; Detail="CPU: $($sysResult.cpu.percent)%"}
    } else {
        Write-Status "System Agent error: $($sysResult.error)" "FAIL" "Red"
        $results += @{Test="System Agent"; Status="FAIL"; Detail=$sysResult.error}
    }
} catch {
    Write-Status "System Agent failed: $_" "FAIL" "Red"
    $results += @{Test="System Agent"; Status="FAIL"; Detail=$_.Exception.Message}
}

# Test 3: Deep Search Harvester
Write-Host "`n[3/6] Testing Deep Search Harvester..." -ForegroundColor Cyan
try {
    $searchResult = python src/api/workers/search_harvester.py "cyberpunk 2077" | ConvertFrom-Json
    if ($searchResult.success -and $searchResult.images.Count -gt 0) {
        Write-Status "Deep Search working - Found $($searchResult.results.Count) text + $($searchResult.images.Count) images" "PASS" "Green"
        $results += @{Test="Deep Search"; Status="PASS"; Detail="$($searchResult.results.Count) text, $($searchResult.images.Count) images"}
    } elseif ($searchResult.success) {
        Write-Status "Search working but no images returned" "WARN" "Yellow"
        $results += @{Test="Deep Search"; Status="WARN"; Detail="No images"}
    } else {
        Write-Status "Search failed: $($searchResult.error)" "FAIL" "Red"
        $results += @{Test="Deep Search"; Status="FAIL"; Detail=$searchResult.error}
    }
} catch {
    Write-Status "Search harvester failed: $_" "FAIL" "Red"
    $results += @{Test="Deep Search"; Status="FAIL"; Detail=$_.Exception.Message}
}

# Test 4: Dependencies
Write-Host "`n[4/6] Testing Python Dependencies..." -ForegroundColor Cyan
try {
    python -c "import psutil, duckduckgo_search" 2>&1 | Out-Null
    Write-Status "All dependencies installed (psutil, duckduckgo_search)" "PASS" "Green"
    $results += @{Test="Dependencies"; Status="PASS"; Detail="All present"}
} catch {
    Write-Status "Missing dependencies. Run: pip install psutil duckduckgo_search" "FAIL" "Red"
    $results += @{Test="Dependencies"; Status="FAIL"; Detail="Missing packages"}
}

# Test 5: File Structure
Write-Host "`n[5/6] Testing File Structure..." -ForegroundColor Cyan
$requiredFiles = @(
    "src/api/workers/search_harvester.py",
    "src/api/workers/system_agent.py"
)
$allPresent = $true
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Status "Found $file" "PASS" "Green"
    } else {
        Write-Status "Missing $file" "FAIL" "Red"
        $allPresent = $false
    }
}
$results += @{Test="File Structure"; Status=$(if($allPresent){"PASS"}else{"FAIL"}); Detail="$(if($allPresent){"All present"}else{"Missing files"})"}

# Test 6: API Connectivity (if Deep scan requested)
if ($Deep) {
    Write-Host "`n[6/6] Deep Scan: Network Connectivity..." -ForegroundColor Cyan
    try {
        $testConn = Test-Connection -ComputerName duckduckgo.com -Count 1 -Quiet
        if ($testConn) {
            Write-Status "Internet connectivity confirmed" "PASS" "Green"
            $results += @{Test="Network"; Status="PASS"; Detail="Connected"}
        } else {
            Write-Status "No internet connection" "FAIL" "Red"
            $results += @{Test="Network"; Status="FAIL"; Detail="No connectivity"}
        }
    } catch {
        Write-Status "Network test failed" "FAIL" "Red"
        $results += @{Test="Network"; Status="FAIL"; Detail=$_.Exception.Message}
    }
} else {
    Write-Host "`n[6/6] Skipped (use -Deep for network test)" -ForegroundColor Gray
    $results += @{Test="Network"; Status="SKIP"; Detail="Not tested"}
}

# Summary
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║                      AUDIT SUMMARY                           ║" -ForegroundColor Magenta
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta

$passed = ($results | Where-Object { $_.Status -eq "PASS" }).Count
$failed = ($results | Where-Object { $_.Status -eq "FAIL" }).Count
$warnings = ($results | Where-Object { $_.Status -eq "WARN" }).Count

Write-Host "Total Tests: $($results.Count) | ✅ Passed: $passed | ❌ Failed: $failed | ⚠️ Warnings: $warnings" -ForegroundColor White

if ($failed -eq 0) {
    Write-Host "`n🚀 ALL SYSTEMS SOVEREIGN - Ready for deployment!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n⚠️  SYSTEMS REQUIRE ATTENTION - Check failures above" -ForegroundColor Yellow
    exit 1
}

