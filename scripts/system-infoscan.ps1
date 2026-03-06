# 🏛️ REZ HIVE - FULL SYSTEM AUDIT
# Captures complete local state for Genesis verification

$auditTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$auditFile = "REZ_HIVE_AUDIT_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  🏛️  REZ HIVE - FULL SOVEREIGN SYSTEM AUDIT                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "Started: $auditTime" -ForegroundColor White
Write-Host ""

# ===================================================
# 1. SYSTEM INFORMATION
# ===================================================
Write-Host "📊 1. SYSTEM INFORMATION" -ForegroundColor Yellow
$systemInfo = @"
SYSTEM INFORMATION
==================
Audit Time: $auditTime
Hostname: $(hostname)
OS: $(Get-ComputerInfo -Property WindowsProductName, WindowsVersion | Format-List | Out-String -Width 200)
PowerShell Version: $($PSVersionTable.PSVersion)
Path: $(Get-Location)

"@
Write-Host $systemInfo

# ===================================================
# 2. DIRECTORY STRUCTURE
# ===================================================
Write-Host "📁 2. DIRECTORY STRUCTURE" -ForegroundColor Yellow
$dirStructure = Get-ChildItem -Path . -Recurse -Directory | ForEach-Object { $_.FullName } | Out-String
Write-Host "Found $((Get-ChildItem -Recurse -Directory).Count) directories" -ForegroundColor Green

# ===================================================
# 3. FILE INVENTORY (All files)
# ===================================================
Write-Host "📄 3. FILE INVENTORY" -ForegroundColor Yellow
$allFiles = Get-ChildItem -Path . -Recurse -File | Select-Object FullName, Length, LastWriteTime
$totalFiles = $allFiles.Count
$totalSize = ($allFiles | Measure-Object -Property Length -Sum).Sum / 1MB
Write-Host "Total Files: $totalFiles" -ForegroundColor Cyan
Write-Host "Total Size: $([math]::Round($totalSize, 2)) MB" -ForegroundColor Cyan

# ===================================================
# 4. BACKEND FILES (Python)
# ===================================================
Write-Host "🐍 4. BACKEND PYTHON FILES" -ForegroundColor Yellow
$pythonFiles = Get-ChildItem -Path "backend" -Recurse -Filter "*.py" -ErrorAction SilentlyContinue
$pythonCount = $pythonFiles.Count
Write-Host "Python Files: $pythonCount" -ForegroundColor Green

$pythonDetails = @()
foreach ($file in $pythonFiles) {
    $lines = (Get-Content $file.FullName | Measure-Object -Line).Lines
    $pythonDetails += [PSCustomObject]@{
        File = $file.Name
        Path = $file.FullName.Replace((Get-Location).Path, "").TrimStart("\")
        Lines = $lines
        SizeKB = [math]::Round($file.Length / 1KB, 2)
    }
}
$pythonDetails | Format-Table -Property File, Lines, SizeKB -AutoSize

# ===================================================
# 5. FRONTEND FILES (TypeScript/TSX)
# ===================================================
Write-Host "⚛️ 5. FRONTEND TSX FILES" -ForegroundColor Yellow
$tsxFiles = Get-ChildItem -Path "src" -Recurse -Filter "*.tsx" -ErrorAction SilentlyContinue
$tsxCount = $tsxFiles.Count
Write-Host "TSX Files: $tsxCount" -ForegroundColor Green

$tsxDetails = @()
foreach ($file in $tsxFiles) {
    $lines = (Get-Content $file.FullName | Measure-Object -Line).Lines
    $tsxDetails += [PSCustomObject]@{
        File = $file.Name
        Path = $file.FullName.Replace((Get-Location).Path, "").TrimStart("\")
        Lines = $lines
        SizeKB = [math]::Round($file.Length / 1KB, 2)
    }
}
$tsxDetails | Format-Table -Property File, Lines, SizeKB -AutoSize

# ===================================================
# 6. CONFIGURATION FILES
# ===================================================
Write-Host "⚙️ 6. CONFIGURATION FILES" -ForegroundColor Yellow
$configFiles = @(
    "package.json",
    "next.config.js",
    "tailwind.config.js",
    "postcss.config.mjs",
    ".gitignore",
    "README.md",
    "LICENSE.md",
    "RELEASE_NOTES.md"
)

foreach ($file in $configFiles) {
    if (Test-Path $file) {
        $size = (Get-Item $file).Length / 1KB
        Write-Host "  ✅ $file ($([math]::Round($size, 2)) KB)" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $file (MISSING)" -ForegroundColor Red
    }
}

# ===================================================
# 7. DATABASE & LOGS
# ===================================================
Write-Host "🗄️ 7. DATABASE & LOGS" -ForegroundColor Yellow
$dbFile = "backend\rez_hive.db"
if (Test-Path $dbFile) {
    $dbSize = (Get-Item $dbFile).Length / 1MB
    Write-Host "  ✅ Database: rez_hive.db ($([math]::Round($dbSize, 2)) MB)" -ForegroundColor Green
} else {
    Write-Host "  ⚠️ Database: Not found (will be created on first run)" -ForegroundColor Yellow
}

$logFiles = Get-ChildItem -Path "logs" -Filter "*.log" -ErrorAction SilentlyContinue
if ($logFiles) {
    Write-Host "  📝 Logs: $($logFiles.Count) files" -ForegroundColor Green
    foreach ($log in $logFiles) {
        $logSize = $log.Length / 1KB
        Write-Host "      • $($log.Name) ($([math]::Round($logSize, 2)) KB)" -ForegroundColor Gray
    }
} else {
    Write-Host "  ⚠️ No log files found" -ForegroundColor Yellow
}

# ===================================================
# 8. CHROMA DATA
# ===================================================
Write-Host "🎯 8. CHROMA VECTOR DATA" -ForegroundColor Yellow
$chromaPath = "chroma_data"
if (Test-Path $chromaPath) {
    $chromaSize = (Get-ChildItem -Path $chromaPath -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1MB
    $chromaFiles = (Get-ChildItem -Path $chromaPath -Recurse -File).Count
    Write-Host "  ✅ ChromaDB: $chromaFiles files, $([math]::Round($chromaSize, 2)) MB" -ForegroundColor Green
} else {
    Write-Host "  ⚠️ Chroma data not found (optional)" -ForegroundColor Yellow
}

# ===================================================
# 9. STATE LEDGER
# ===================================================
Write-Host "📜 9. ZERO-DRIFT LEDGER" -ForegroundColor Yellow
$ledgerPath = "logs\state_ledger.json"
if (Test-Path $ledgerPath) {
    $ledgerContent = Get-Content $ledgerPath -Raw | ConvertFrom-Json
    $ledgerSize = (Get-Item $ledgerPath).Length / 1KB
    Write-Host "  ✅ Ledger: state_ledger.json ($([math]::Round($ledgerSize, 2)) KB)" -ForegroundColor Green
    Write-Host "  📊 Genesis: $($ledgerContent.genesis_block.timestamp)" -ForegroundColor Cyan
    Write-Host "  📊 Version: $($ledgerContent.genesis_block.version)" -ForegroundColor Cyan
    Write-Host "  📊 Drift Events: $($ledgerContent.genesis_block.drift_events)" -ForegroundColor Cyan
} else {
    Write-Host "  ❌ Ledger not found - Run genesis generation!" -ForegroundColor Red
}

# ===================================================
# 10. GIT STATUS
# ===================================================
Write-Host "🔧 10. GIT STATUS" -ForegroundColor Yellow
if (Test-Path ".git") {
    $branch = git branch --show-current
    $commit = git log -1 --format="%h - %s"
    $status = git status --porcelain | Measure-Object | Select-Object -ExpandProperty Count
    Write-Host "  ✅ Git repository: $branch" -ForegroundColor Green
    Write-Host "  📌 Last commit: $commit" -ForegroundColor Cyan
    if ($status -gt 0) {
        Write-Host "  ⚠️ Uncommitted changes: $status files" -ForegroundColor Yellow
    } else {
        Write-Host "  ✅ Working tree clean" -ForegroundColor Green
    }
} else {
    Write-Host "  ⚠️ Not a git repository" -ForegroundColor Yellow
}

# ===================================================
# 11. SUMMARY STATISTICS
# ===================================================
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║  📊 AUDIT SUMMARY                                           ║" -ForegroundColor Magenta
Write-Host "╠════════════════════════════════════════════════════════════╣" -ForegroundColor Magenta
Write-Host "║" -ForegroundColor White
Write-Host "║  Total Files: $totalFiles" -ForegroundColor White
Write-Host "║  Total Size: $([math]::Round($totalSize, 2)) MB" -ForegroundColor White
Write-Host "║" -ForegroundColor White
Write-Host "║  Python Files: $pythonCount ($($pythonDetails | Measure-Object -Property Lines -Sum).Sum lines)" -ForegroundColor Cyan
Write-Host "║  TSX Files: $tsxCount ($($tsxDetails | Measure-Object -Property Lines -Sum).Sum lines)" -ForegroundColor Cyan
Write-Host "║" -ForegroundColor White
Write-Host "║  Database: $(if (Test-Path $dbFile) { '✅ Present' } else { '⚠️ Not found' })" -ForegroundColor $(if (Test-Path $dbFile) { 'Green' } else { 'Yellow' })
Write-Host "║  ChromaDB: $(if (Test-Path $chromaPath) { '✅ Present' } else { '⚠️ Optional' })" -ForegroundColor $(if (Test-Path $chromaPath) { 'Green' } else { 'Yellow' })
Write-Host "║  Ledger: $(if (Test-Path $ledgerPath) { '✅ Sealed' } else { '❌ Missing' })" -ForegroundColor $(if (Test-Path $ledgerPath) { 'Green' } else { 'Red' })
Write-Host "║" -ForegroundColor White
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

# ===================================================
# 12. SAVE AUDIT TO FILE
# ===================================================
$auditContent = @"
🏛️ REZ HIVE - FULL SOVEREIGN SYSTEM AUDIT
==========================================
Generated: $auditTime
Path: $(Get-Location)

SYSTEM INFO
-----------
Hostname: $(hostname)
OS: $(Get-ComputerInfo -Property WindowsProductName).WindowsProductName

FILE COUNTS
-----------
Total Files: $totalFiles ($([math]::Round($totalSize, 2)) MB)
Python Files: $pythonCount
TSX Files: $tsxCount

KEY FILES
---------
Database: $(if (Test-Path $dbFile) { "Present ($([math]::Round((Get-Item $dbFile).Length/1MB, 2)) MB)" } else { "Not found" })
Ledger: $(if (Test-Path $ledgerPath) { "Present" } else { "Missing" })
Chroma: $(if (Test-Path $chromaPath) { "Present" } else { "Not found" })

GIT STATUS
----------
Branch: $(if (Test-Path ".git") { git branch --show-current } else { "Not a repo" })
Last Commit: $(if (Test-Path ".git") { git log -1 --format="%h - %s" } else { "N/A" })
"@

$auditContent | Out-File -FilePath $auditFile -Encoding UTF8
Write-Host "✅ Audit saved to: $auditFile" -ForegroundColor Green
Write-Host ""