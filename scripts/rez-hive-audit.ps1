# rez-hive-audit.ps1
# Full Backend & Frontend Test Audit for REZ HIVE

param(
    [switch]$Quick,           # Skip slow tests (RAG, web search)
    [switch]$Repair           # Attempt to fix minor issues (like missing env vars)
)

$REPORT = @()
$ERRORS = 0
$WARNINGS = 0

function Write-TestResult {
    param($Category, $Test, $Status, $Message = "")
    $icon = switch ($Status) {
        "PASS" { "✅" }
        "WARN" { "⚠️" ; $script:WARNINGS++ }
        "FAIL" { "❌" ; $script:ERRORS++ }
        default { "🔍" }
    }
    $line = "$icon [$Category] $Test"
    if ($Message) { $line += " – $Message" }
    $script:REPORT += $line
    Write-Host $line -ForegroundColor $(switch ($Status) {
        "PASS" { "Green" }
        "WARN" { "Yellow" }
        "FAIL" { "Red" }
        default { "Gray" }
    })
}

Write-Host "`n🏛️  REZ HIVE – FULL SYSTEM AUDIT" -ForegroundColor Cyan
Write-Host "====================================`n"

# --------------------------------------------------------------------
# 1. Environment & Configuration
# --------------------------------------------------------------------
Write-Host "📁 Checking environment..." -ForegroundColor Cyan

if (Test-Path ".env.local") {
    $envContent = Get-Content ".env.local" -Raw
    Write-TestResult "Config" ".env.local exists" "PASS"
    $requiredVars = @("OLLAMA_BASE_URL", "OLLAMA_MODEL", "API_URL", "SEARXNG_URL")
    $missing = @()
    foreach ($v in $requiredVars) {
        if ($envContent -notmatch "^$v=") { $missing += $v }
    }
    if ($missing.Count -eq 0) {
        Write-TestResult "Config" "All required env vars present" "PASS"
    } else {
        Write-TestResult "Config" "Missing env vars: $($missing -join ', ')" "WARN"
        if ($Repair) {
            Add-Content ".env.local" "`n$($missing[0])=http://localhost:8001"
            Write-TestResult "Config" "Attempted repair (add missing)" "WARN"
        }
    }
} else {
    Write-TestResult "Config" ".env.local missing" "FAIL"
}

# --------------------------------------------------------------------
# 2. Core Services (Port Checks)
# --------------------------------------------------------------------
Write-Host "`n🔌 Checking core services..." -ForegroundColor Cyan

$services = @(
    @{Name="Next.js"; Port=3000; Expected="Web UI"},
    @{Name="FastAPI"; Port=8001; Expected="API backend"},
    @{Name="ChromaDB"; Port=8000; Expected="Vector DB"},
    @{Name="Ollama"; Port=11434; Expected="LLM server"}
)
foreach ($svc in $services) {
    $test = netstat -ano | findstr ":$($svc.Port)" | findstr "LISTENING"
    if ($test) {
        Write-TestResult "Service" $svc.Name "PASS" "$($svc.Expected) on port $($svc.Port)"
    } else {
        Write-TestResult "Service" $svc.Name "FAIL" "$($svc.Expected) not listening"
    }
}

# SearXNG (Docker)
$docker = docker ps --filter "name=searxng" --format "{{.Status}}" 2>$null
if ($docker -match "Up") {
    Write-TestResult "Service" "SearXNG" "PASS" "Docker container running"
} else {
    Write-TestResult "Service" "SearXNG" "WARN" "Not running (optional)"
}

# --------------------------------------------------------------------
# 3. API Endpoint Tests
# --------------------------------------------------------------------
Write-Host "`n🧪 Testing API endpoints..." -ForegroundColor Cyan

# Helper
function Test-Endpoint {
    param($Name, $Url, $Method="GET", $Body=$null, $ExpectStatus=200)
    try {
        if ($Method -eq "GET") {
            $r = Invoke-WebRequest -Uri $Url -Method GET -TimeoutSec 5 -ErrorAction Stop
        } else {
            $r = Invoke-WebRequest -Uri $Url -Method POST -Body $Body -ContentType "application/json" -TimeoutSec 5 -ErrorAction Stop
        }
        if ($r.StatusCode -eq $ExpectStatus) {
            Write-TestResult "API" $Name "PASS"
        } else {
            Write-TestResult "API" $Name "FAIL" "HTTP $($r.StatusCode) (expected $ExpectStatus)"
        }
    } catch {
        Write-TestResult "API" $Name "FAIL" $_.Exception.Message
    }
}

# FastAPI endpoints
Test-Endpoint "FastAPI status" "http://localhost:8001/api/status"
Test-Endpoint "FastAPI root" "http://localhost:8001/"

# Next.js proxy (should forward to FastAPI)
Test-Endpoint "Next.js /api/status" "http://localhost:3000/api/status"

# ChromaDB heartbeat
Test-Endpoint "ChromaDB heartbeat" "http://localhost:8000/api/v1/heartbeat"

# MCP endpoints (via FastAPI) – if any are exposed
Test-Endpoint "System vitals" "http://localhost:8001/api/system/vitals"
Test-Endpoint "Notes (list)" "http://localhost:8001/api/notes/search/test"  # may 404 if no notes

# Kernel streaming endpoint (just test that it's reachable)
Test-Endpoint "Kernel POST" "http://localhost:8001/api/kernel" -Method POST -Body '{"task":"hello"}' -ExpectStatus 200

# --------------------------------------------------------------------
# 4. MCP Servers (Process Check)
# --------------------------------------------------------------------
Write-Host "`n🤖 Checking MCP servers..." -ForegroundColor Cyan

$mcpScripts = @("executive_mcp.py", "system_mcp.py", "process_mcp.py", "research_mcp.py", "rag_pipeline.py")
$pythonProcs = Get-Process -Name python -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id

foreach ($script in $mcpScripts) {
    # Check if any python process has the script name in its command line (crude but works)
    $found = $false
    foreach ($pid in $pythonProcs) {
        $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId=$pid").CommandLine
        if ($cmdLine -match [regex]::Escape($script)) {
            $found = $true
            break
        }
    }
    if ($found) {
        Write-TestResult "MCP" $script "PASS"
    } else {
        Write-TestResult "MCP" $script "WARN" "Not running (may be launched later)"
    }
}

# --------------------------------------------------------------------
# 5. Frontend Load Test (basic)
# --------------------------------------------------------------------
Write-Host "`n🖥️  Testing frontend..." -ForegroundColor Cyan

try {
    $homePage = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 5 -ErrorAction Stop
    if ($homePage.Content -match "REZ HIVE" -or $homePage.Content -match "sovereign") {
        Write-TestResult "Frontend" "Homepage loads" "PASS"
    } else {
        Write-TestResult "Frontend" "Homepage loads" "WARN" "Content missing expected keywords"
    }
} catch {
    Write-TestResult "Frontend" "Homepage access" "FAIL" $_.Exception.Message
}

# --------------------------------------------------------------------
# 6. Launcher Validation
# --------------------------------------------------------------------
Write-Host "`n🚀 Checking launcher scripts..." -ForegroundColor Cyan

if (Test-Path "launch-rez-hive-master.bat") {
    Write-TestResult "Launcher" "Master launcher exists" "PASS"
} else {
    Write-TestResult "Launcher" "Master launcher missing" "WARN" "Use 'launch-rez-hive.bat' or create master"
}
if (Test-Path "launch-rez-hive.bat") {
    Write-TestResult "Launcher" "Basic launcher exists" "PASS"
} else {
    Write-TestResult "Launcher" "Basic launcher missing" "WARN"
}

# --------------------------------------------------------------------
# 7. Optional: SearXNG / RAG tests (skip with -Quick)
# --------------------------------------------------------------------
if (-not $Quick) {
    Write-Host "`n🌐 Testing advanced features..." -ForegroundColor Cyan

    # SearXNG search
    try {
        $search = Invoke-RestMethod "http://localhost:8080/search?q=sovereign%20AI&format=json" -TimeoutSec 10 -ErrorAction Stop
        if ($search.results.Count -gt 0) {
            Write-TestResult "Advanced" "SearXNG search" "PASS"
        } else {
            Write-TestResult "Advanced" "SearXNG search" "WARN" "No results returned"
        }
    } catch {
        Write-TestResult "Advanced" "SearXNG search" "FAIL" $_.Exception.Message
    }

    # RAG index a test file (if any)
    $testDoc = "documents\test.txt"
    if (Test-Path $testDoc) {
        try {
            $rag = Invoke-RestMethod "http://localhost:8001/api/rag/index" -Method Post -Body (@{file_path=$testDoc} | ConvertTo-Json) -ContentType "application/json" -ErrorAction Stop
            Write-TestResult "Advanced" "RAG indexing" "PASS"
        } catch {
            Write-TestResult "Advanced" "RAG indexing" "FAIL" $_.Exception.Message
        }
    } else {
        Write-TestResult "Advanced" "RAG indexing" "SKIP" "No test document found"
    }
} else {
    Write-Host "`n⏩ Skipping advanced tests (use -Quick to bypass)." -ForegroundColor Gray
}

# --------------------------------------------------------------------
# Summary
# --------------------------------------------------------------------
Write-Host "`n====================================" -ForegroundColor Cyan
Write-Host "📊 AUDIT SUMMARY" -ForegroundColor White
Write-Host "   PASS: $(([regex]::Matches($REPORT, "✅").Count))"
Write-Host "   WARN: $WARNINGS"
Write-Host "   FAIL: $ERRORS"
Write-Host "====================================" -ForegroundColor Cyan

if ($ERRORS -eq 0 -and $WARNINGS -eq 0) {
    Write-Host "🏛️  REZ HIVE IS FULLY OPERATIONAL!" -ForegroundColor Green
} elseif ($ERRORS -eq 0) {
    Write-Host "⚠️  REZ HIVE is running with some warnings (optional components)." -ForegroundColor Yellow
} else {
    Write-Host "❌ Some critical components failed. Check the logs above." -ForegroundColor Red
}

Write-Host "`nDetailed report saved to: rez-hive-audit.log`n"
$REPORT | Out-File -FilePath "rez-hive-audit.log" -Encoding UTF8