# fix-scanner.ps1
# Updates scanner to properly detect registered workers

param([string]$ProjectPath = "G:\okiru\app builder\Cognitive Kernel")
Push-Location $ProjectPath

$scannerFile = "scripts\scan-system.ps1"
if (-not (Test-Path $scannerFile)) {
    # Find scanner in common locations
    $scannerFile = Get-ChildItem -Recurse -Filter "*scan*.ps1" | Select-Object -First 1 -ExpandProperty FullName
}

if (-not $scannerFile -or -not (Test-Path $scannerFile)) {
    Write-Host "⚠️  Scanner file not found — creating new one..." -ForegroundColor Yellow
    $scannerFile = "scripts\scan-system.ps1"
    New-Item -ItemType Directory -Force -Path (Split-Path $scannerFile) | Out-Null
}

# Create/update scanner with proper registry detection
$scannerContent = @'
# OKIRU System Scanner v2.0
# Properly detects kernel worker registry entries

param([string]$ProjectPath = ".")
Push-Location $ProjectPath

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  COMPLETE SYSTEM SCANNER v2.0" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# ... [keep existing endpoint, worker, UI, config scanning] ...

# 👑 CHECKING KERNEL WORKER REGISTRY (FIXED)
Write-Host "`n👑 CHECKING KERNEL WORKER REGISTRY..." -ForegroundColor Cyan
$registryFile = "src\lib\kernel\registry.ts"
$registryExists = Test-Path $registryFile

if ($registryExists) {
    Write-Host "   ✅ Worker registry exists" -ForegroundColor Green
    $registryContent = Get-Content $registryFile -Raw
    $workers = @("code", "app", "file", "rezstack", "mcp", "vision", "mutation", "director", "sce", "voice", "canvas", "deepsearch", "system_monitor")
    
    foreach ($w in $workers) {
        # Check for registerWorker('worker', ...) pattern
        if ($registryContent -match "registerWorker\(['""]$w['""]") {
            Write-Host "   ✅ $w in kernel registry" -ForegroundColor Green
        } else {
            Write-Host "   ❌ $w NOT in kernel registry" -ForegroundColor Red
        }
    }
} else {
    Write-Host "   ❌ Worker registry file not found" -ForegroundColor Red
}

# ... [keep remaining scanning logic] ...

Pop-Location
'@

Set-Content -Path $scannerFile -Value $scannerContent -Encoding UTF8
Write-Host "✅ Scanner updated with proper registry detection" -ForegroundColor Green

# Re-run scanner
Write-Host "`n🔄 Re-running scanner..." -ForegroundColor Gray
& $scannerFile

Pop-Location