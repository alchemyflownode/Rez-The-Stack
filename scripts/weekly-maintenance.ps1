# ═══════════════════════════════════════════════════════════════
# REZ HIVE - Weekly Maintenance Script
# Save as: scripts/weekly-maintenance.ps1
# ═══════════════════════════════════════════════════════════════

Write-Host "`n[REZ HIVE Weekly Maintenance]" -ForegroundColor Cyan
$report = @{}

# 1. Dependency Security Scan
Write-Host "`n[1] Security Scan" -ForegroundColor Yellow

# Node.js
Write-Host "  Checking Node.js dependencies..." -ForegroundColor Gray
$npmAudit = npm audit --json 2>$null | ConvertFrom-Json
$report.NodeVulns = $npmAudit.metadata?.vulnerabilities?.total ?? 0
Write-Host "    Vulnerabilities: $($report.NodeVulns)" -ForegroundColor $(if($report.NodeVulns -eq 0){"Green"}else{"Yellow"})

# Python
Write-Host "  Checking Python dependencies..." -ForegroundColor Gray
$ pip-audit 2>&1 | Select-String "vulnerability" | ForEach-Object {
    Write-Host "    ⚠ $_" -ForegroundColor Yellow
    $report.PythonVulns++
}
if (-not $report.PythonVulns) {
    Write-Host "    ✓ No vulnerabilities found" -ForegroundColor Green
    $report.PythonVulns = 0
}

# 2. Model Updates
Write-Host "`n[2] Model Updates" -ForegroundColor Yellow
$ollamaUpdate = ollama list 2>&1
Write-Host "  Installed models:" -ForegroundColor Gray
$ollamaUpdate | Select-Object -First 10 | ForEach-Object { Write-Host "    → $_" -ForegroundColor Gray }

# 3. Log Review
Write-Host "`n[3] Audit Log Review" -ForegroundColor Yellow
if (Test-Path "logs/audit.jsonl") {
    $logCount = (Get-Content "logs/audit.jsonl").Count
    $logSize = (Get-Item "logs/audit.jsonl").Length / 1KB
    Write-Host "  Audit log: $logCount entries ($([math]::Round($logSize, 2)) KB)" -ForegroundColor Gray
    
    # Show last 5 entries (anonymized)
    Write-Host "  Recent activity:" -ForegroundColor Gray
    Get-Content "logs/audit.jsonl" | Select-Object -Last 5 | ForEach-Object {
        $entry = $_ | ConvertFrom-Json
        Write-Host "    $($entry.timestamp): $($entry.action)" -ForegroundColor Gray
    }
} else {
    Write-Host "  ⚠ No audit log found" -ForegroundColor Yellow
}

# 4. Disk Usage
Write-Host "`n[4] Storage Usage" -ForegroundColor Yellow
$nodeModules = (Get-Item "node_modules" -ErrorAction SilentlyContinue).Length / 1MB
$models = (ollama list 2>&1 | Measure-Object -Property Length -Sum).Sum / 1GB
Write-Host "  node_modules: $([math]::Round($nodeModules, 2)) MB" -ForegroundColor Gray
Write-Host "  Ollama models: $([math]::Round($models, 2)) GB" -ForegroundColor Gray

# 5. Backup (Optional)
Write-Host "`n[5] Backup" -ForegroundColor Yellow
$backupDir = "backups/weekly-$(Get-Date -Format 'yyyyMMdd')"
New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
Copy-Item ".env.local" -Destination "$backupDir/" -ErrorAction SilentlyContinue
Copy-Item "logs/audit.jsonl" -Destination "$backupDir/" -ErrorAction SilentlyContinue
Write-Host "  ✓ Backup created: $backupDir" -ForegroundColor Green

# Export Report
$reportPath = "reports/weekly-$(Get-Date -Format 'yyyyMMdd').json"
$report | ConvertTo-Json | Out-File $reportPath
Write-Host "`n  Report saved: $reportPath" -ForegroundColor Gray

Write-Host "`n[✓] Weekly maintenance complete`n" -ForegroundColor Cyan