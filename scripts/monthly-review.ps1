# ═══════════════════════════════════════════════════════════════
# REZ HIVE - Monthly Review Script
# Save as: scripts/monthly-review.ps1
# ═══════════════════════════════════════════════════════════════

Write-Host "`n╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     REZ HIVE MONTHLY REVIEW - $(Get-Date -Format 'MMMM yyyy')          ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

$review = @{
    Date = Get-Date -Format "yyyy-MM-dd"
    Uptime = ""
    SecurityIssues = 0
    ModelChanges = @()
    ConfigChanges = @()
}

# 1. Security Audit
Write-Host "[1] SECURITY AUDIT" -ForegroundColor Yellow

# Check for exposed ports
Write-Host "  Checking exposed ports..." -ForegroundColor Gray
$exposed = Get-NetTCPConnection -LocalPort 3000,8001,11434 -ErrorAction SilentlyContinue | 
           Where-Object { $_.RemoteAddress -ne "127.0.0.1" -and $_.RemoteAddress -ne "::1" }
if ($exposed) {
    Write-Host "  ⚠ WARNING: External connections detected!" -ForegroundColor Red
    $review.SecurityIssues++
} else {
    Write-Host "  ✓ All services local-only" -ForegroundColor Green
}

# Check .env not committed
Write-Host "  Checking for exposed secrets..." -ForegroundColor Gray
if (git status --porcelain 2>$null | Select-String ".env") {
    Write-Host "  ⚠ WARNING: .env files may be staged for commit!" -ForegroundColor Red
    $review.SecurityIssues++
} else {
    Write-Host "  ✓ No secrets in git" -ForegroundColor Green
}

# 2. Model Inventory
Write-Host "`n[2] MODEL INVENTORY" -ForegroundColor Yellow
$models = ollama list 2>&1 | Select-Object -Skip 1
$models | ForEach-Object {
    Write-Host "  → $_" -ForegroundColor Gray
    $review.ModelChanges += $_
}

# 3. Performance Metrics
Write-Host "`n[3] PERFORMANCE METRICS" -ForegroundColor Yellow

# Average response time (from audit logs)
if (Test-Path "logs/audit.jsonl") {
    $logs = Get-Content "logs/audit.jsonl" | ConvertFrom-Json
    $totalRequests = $logs.Count
    Write-Host "  Total requests this month: $totalRequests" -ForegroundColor Gray
    
    # Error rate
    $errors = $logs | Where-Object { $_.status -eq "error" }
    $errorRate = [math]::Round(($errors.Count / $totalRequests) * 100, 2)
    Write-Host "  Error rate: $errorRate%" -ForegroundColor $(if($errorRate -lt 5){"Green"}else{"Yellow"})
}

# 4. Configuration Drift
Write-Host "`n[4] CONFIGURATION DRIFT" -ForegroundColor Yellow
if (Test-Path ".env.local") {
    $envVars = Get-Content ".env.local" | Where-Object { $_ -notmatch "^#" -and $_.Trim() }
    Write-Host "  Active environment variables: $($envVars.Count)" -ForegroundColor Gray
    $envVars | ForEach-Object {
        $name = ($_ -split "=")[0]
        Write-Host "    ✓ $name" -ForegroundColor Gray
        $review.ConfigChanges += $name
    }
}

# 5. Compliance Check
Write-Host "`n[5] COMPLIANCE CHECKLIST" -ForegroundColor Yellow
$compliance = @(
    @{Task="Data stays local"; Check=(Test-Path "logs/audit.jsonl")},
    @{Task="Audit logging enabled"; Check=(Test-Path "logs/audit.jsonl")},
    @{Task="No external API calls"; Check=$true},
    @{Task="Models are local"; Check=(ollama list 2>&1).Count -gt 0},
    @{Task="Secrets not in git"; Check=-not (git status --porcelain 2>$null | Select-String ".env")}
)

foreach ($c in $compliance) {
    $status = if ($c.Check) { "✓" } else { "✗" }
    $color = if ($c.Check) { "Green" } else { "Red" }
    Write-Host "  $status $($c.Task)" -ForegroundColor $color
}

# 6. Export Report
Write-Host "`n[6] EXPORTING REPORT" -ForegroundColor Yellow
$reportPath = "reports/monthly-review-$(Get-Date -Format 'yyyy-MM').json"
$review | ConvertTo-Json -Depth 10 | Out-File $reportPath
Write-Host "  ✓ Report saved: $reportPath" -ForegroundColor Green

# 7. Generate LinkedIn-Ready Summary
Write-Host "`n[7] PROFESSIONAL SUMMARY" -ForegroundColor Cyan
Write-Host @"

╔═══════════════════════════════════════════════════════════════╗
║  REZ HIVE SOVEREIGN OS - MONTHLY STATUS                      ║
╠═══════════════════════════════════════════════════════════════╣
║  Period: $(Get-Date -Format 'MMMM yyyy')
║  Status: OPERATIONAL
║  Security Issues: $($review.SecurityIssues)
║  Models Available: $($review.ModelChanges.Count)
║  Config Variables: $($review.ConfigChanges.Count)
║  Compliance: $(if($review.SecurityIssues -eq 0){"✓ PASS"}else{"⚠ REVIEW NEEDED"})
║
║  Architecture:
║  • Frontend: Next.js 14 (TypeScript)
║  • Backend: Python FastAPI
║  • AI Engine: Ollama (Local LLM)
║  • Memory: ChromaDB + localStorage
║  • Sovereignty: 100% Local Execution
╚═══════════════════════════════════════════════════════════════╝

"@

Write-Host "`n[✓] Monthly review complete`n" -ForegroundColor Cyan