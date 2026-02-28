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
