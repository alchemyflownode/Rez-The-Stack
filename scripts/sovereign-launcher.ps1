# 🏛️ SOVEREIGN AGENT v3.0 - Context-Aware Healing
# Loops until app runs: Diagnostics → Healing → Launch → Repeat

param(
    [int]$MaxAttempts = 10,
    [int]$Port = 3001,
    [string]$AppName = "REZ HIVE",
    [switch]$RespectUserConfig = $true,
    [switch]$DryRun = $false
)

$attempt = 0
$success = $false
$HealingMemory = @{}
$ProjectIntent = @{}

function Write-Header {
    Clear-Host
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║  🧠 SOVEREIGN AGENT v3.0 - Context-Aware Healing          ║" -ForegroundColor Magenta
    Write-Host "║  $AppName - Intent Recognition + Surgical Repairs         ║" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
    if ($DryRun) { Write-Host "🔍 DRY RUN MODE - No changes will be made" -ForegroundColor Yellow }
}

function Test-App {
    try {
        $r = Invoke-WebRequest "http://localhost:$Port" -TimeoutSec 3 -UseBasicParsing -ErrorAction SilentlyContinue
        return $r.StatusCode -eq 200
    } catch { return $false }
}

function Detect-ProjectIntent {
    Write-Host "`n🧠 PHASE 0: INTENT DETECTION" -ForegroundColor Magenta
    
    $intent = @{
        WantsV4 = $false
        WantsTurbopack = $false
        WantsCustomConfig = $false
        IsProduction = $false
        Confidence = 0
    }
    
    if (Test-Path "package.json") {
        $pkg = Get-Content "package.json" -Raw | ConvertFrom-Json
        if ($pkg.devDependencies.tailwindcss -match "^4") {
            $intent.WantsV4 = $true
            $intent.Confidence += 30
            Write-Host "   📦 Intent: Tailwind v4 explicitly installed" -ForegroundColor Cyan
        }
        if ($pkg.scripts.dev -match "--turbopack") {
            $intent.WantsTurbopack = $true
            $intent.Confidence += 20
            Write-Host "   🚀 Intent: Turbopack explicitly enabled" -ForegroundColor Cyan
        }
    }
    
    if (Test-Path "next.config.js") {
        $config = Get-Content "next.config.js" -Raw
        if ($config -match "images\.domains|rewrites\(\)|redirects\(\)|env\.") {
            $intent.WantsCustomConfig = $true
            $intent.Confidence += 20
            Write-Host "   ⚙️  Intent: Custom Next.js configuration detected" -ForegroundColor Cyan
        }
    }
    
    Write-Host "   Confidence: $($intent.Confidence)%" -ForegroundColor $(if($intent.Confidence -gt 50){"Green"}else{"Yellow"})
    return $intent
}

function Invoke-Diagnostic {
    param([string]$Phase, [hashtable]$Intent)
    
    Write-Host "`n🔍 $Phase" -ForegroundColor Yellow
    
    switch ($Phase) {
        "NODE_STATUS" {
            $procs = Get-Process node -ErrorAction SilentlyContinue
            $port = netstat -ano | Select-String ":$Port"
            Write-Host "   Node processes: $($procs.Count)" -ForegroundColor Gray
            Write-Host "   Port $Port blocked: $($port -ne $null)" -ForegroundColor Gray
            return @{ NodeCount = $procs.Count; PortBlocked = $port -ne $null }
        }
        "TAILWIND_STATE" {
            $info = npm list tailwindcss 2>$null
            $v4installed = $info -match "tailwindcss@4"
            $v3installed = $info -match "tailwindcss@3"
            
            $css = Get-Content "src/app/globals.css" -Raw -ErrorAction SilentlyContinue
            $hasV4Import = $css -match '@import "tailwindcss"'
            $hasV3Directives = $css -match '@tailwind base'
            $hasSpacing = $css -match '--spacing\('
            
            $currentV4 = $v4installed -or $hasV4Import -or $hasSpacing
            $currentV3 = $v3installed -or $hasV3Directives
            
            Write-Host "   Installed: v4=$v4installed, v3=$v3installed" -ForegroundColor Gray
            Write-Host "   Current: $(if($currentV4){'v4'}elseif($currentV3){'v3'}else{'unknown'})" -ForegroundColor Cyan
            Write-Host "   Intent: $(if($Intent.WantsV4){'v4'}else{'v3/unknown'})" -ForegroundColor Magenta
            
            return @{
                CurrentV4 = $currentV4
                CurrentV3 = $currentV3
                IntentV4 = $Intent.WantsV4
                Mismatch = ($Intent.WantsV4 -and $currentV3) -or (-not $Intent.WantsV4 -and $currentV4)
            }
        }
        "CONFIG_STATE" {
            $config = Get-Content "next.config.js" -Raw -ErrorAction SilentlyContinue
            $hasTurbopack = $config -match "turbopack\s*:\s*true"
            $hasFallbacks = $config -match "fs:\s*false"
            $hasCustom = $config -match "images\.|rewrites|redirects"
            
            Write-Host "   Turbopack enabled: $hasTurbopack" -ForegroundColor Gray
            Write-Host "   Webpack fallbacks: $hasFallbacks" -ForegroundColor Gray
            
            return @{
                TurbopackEnabled = $hasTurbopack
                HasFallbacks = $hasFallbacks
                HasCustom = $hasCustom
                NeedsTurbopackFix = $hasTurbopack -and -not $Intent.WantsTurbopack
            }
        }
    }
}

function Protect-File {
    param([string]$Path)
    
    if (Test-Path $Path) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupPath = "$Path.sov_bak_$timestamp"
        Copy-Item $Path $backupPath -Force
        Write-Host "   💾 Backup created: $backupPath" -ForegroundColor Gray
        return $backupPath
    }
    return $null
}

function Repair-NextConfig {
    param([string]$FixType)
    
    $path = "next.config.js"
    if (-not (Test-Path $path)) { return }
    
    $backup = Protect-File -Path $path
    $content = Get-Content $path -Raw
    
    switch ($FixType) {
        "DISABLE_TURBOPACK" {
            if ($content -match "turbopack\s*:\s*true") {
                $newContent = $content -replace "turbopack\s*:\s*true", "turbopack: false"
                Set-Content $path $newContent -NoNewline
                Write-Host "   🔧 Surgical fix: Disabled turbopack" -ForegroundColor Green
            }
        }
        "FIX_WEBPACK_FALLBACKS" {
            if ($content -match "fallback.*?\{" -and $content -notmatch "fs:\s*false") {
                $newContent = $content -replace 
                    "(fallback:\s*\{)", 
                    "`$1`n        fs: false,`n        path: false,`n        os: false,"
                Set-Content $path $newContent -NoNewline
                Write-Host "   🔧 Surgical fix: Added Node.js fallbacks" -ForegroundColor Green
            }
        }
    }
}

function Invoke-Heal {
    param([string]$Fix, [hashtable]$Intent, [hashtable]$Diagnostics)
    
    Write-Host "`n🔧 $Fix" -ForegroundColor Green
    
    switch ($Fix) {
        "KILL_NODE" {
            Get-Process node -ErrorAction SilentlyContinue | Stop-Process -Force
            Start-Sleep 2
            Write-Host "   ✓ Killed" -ForegroundColor Green
        }
        "CLEAR_CACHE" {
            Remove-Item -Recurse -Force .next -ErrorAction SilentlyContinue
            Remove-Item -Recurse -Force node_modules/.cache -ErrorAction SilentlyContinue
            Write-Host "   ✓ Cache cleared" -ForegroundColor Green
        }
        "FIX_TAILWIND" {
            npm uninstall @tailwindcss/postcss -ErrorAction SilentlyContinue
            npm install -D tailwindcss@3.4.17 postcss autoprefixer --save-exact
            Write-Host "   ✓ v3 locked" -ForegroundColor Green
        }
        "FIX_SCRIPT" {
            $pkg = Get-Content "package.json" -Raw | ConvertFrom-Json
            $pkg.scripts.dev = "next dev -p $Port"
            $pkg | ConvertTo-Json -Depth 10 | Out-File "package.json" -Encoding UTF8
            Write-Host "   ✓ Removed --turbopack" -ForegroundColor Green
        }
    }
}

# ============================================
# MAIN SOVEREIGN LOOP
# ============================================

while ($attempt -lt $MaxAttempts -and -not $success) {
    $attempt++
    Write-Header
    
    Write-Host "ATTEMPT $attempt of $MaxAttempts" -ForegroundColor Cyan
    Write-Host "Time: $(Get-Date -Format 'HH:mm:ss')`n" -ForegroundColor Gray
    
    # PHASE 0: Detect Intent (Only once)
    if ($attempt -eq 1) {
        $ProjectIntent = Detect-ProjectIntent
    }
    
    # PHASE 1: Diagnostics
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    $node = Invoke-Diagnostic "NODE_STATUS" -Intent $ProjectIntent
    $tw = Invoke-Diagnostic "TAILWIND_STATE" -Intent $ProjectIntent
    $cfg = Invoke-Diagnostic "CONFIG_STATE" -Intent $ProjectIntent
    
    # PHASE 2: Decision Engine
    Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host "PHASE 2: SOVEREIGN DECISION ENGINE" -ForegroundColor Magenta
    
    $fixes = @()
    
    if ($node.NodeCount -gt 0 -or $node.PortBlocked) { $fixes += "KILL_NODE" }
    if ($tw.Mismatch) { $fixes += "FIX_TAILWIND" }
    if ($cfg.NeedsTurbopackFix) { $fixes += "FIX_SCRIPT" }
    if ($cfg.HasCustom -and -not $cfg.HasFallbacks) { Repair-NextConfig -FixType "FIX_WEBPACK_FALLBACKS" }
    if ($fixes.Count -gt 0) { $fixes += "CLEAR_CACHE" }
    
    # Execute fixes
    if ($fixes.Count -eq 0) {
        Write-Host "`n✅ No issues detected" -ForegroundColor Green
    } else {
        Write-Host "`nApplying $($fixes.Count) fixes..." -ForegroundColor Yellow
        foreach ($fix in $fixes) { Invoke-Heal $fix -Intent $ProjectIntent -Diagnostics @{} }
    }
    
    # PHASE 3: Launch
    Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host "PHASE 3: LAUNCH" -ForegroundColor Green
    
    if ($DryRun) {
        Write-Host "🔍 DRY RUN: Would launch npm run dev" -ForegroundColor Yellow
        $success = $true
        break
    }
    
    Write-Host "`n🚀 Starting... (monitoring for 30s max)" -ForegroundColor Green
    
    $proc = Start-Process "npm" "run","dev" -PassThru -WindowStyle Normal
    $wait = 0
    
    while ($wait -lt 30) {
        Start-Sleep 1
        $wait++
        Write-Host "   $wait`s..." -ForegroundColor DarkGray -NoNewline; Write-Host ""
        
        if (Test-App) { $running = $true; break }
        if ($proc.HasExited) { break }
    }
    
    if ($running) {
        Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║  ✅ SUCCESS! App running at http://localhost:$Port            ║" -ForegroundColor Green
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
        $success = $true
    } else {
        Write-Host "`n❌ Failed, retrying in 3s..." -ForegroundColor Red
        if (-not $proc.HasExited) { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue }
        Start-Sleep 3
    }
}

if (-not $success) {
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║  ❌ ALL ATTEMPTS FAILED - Manual intervention required       ║" -ForegroundColor Red
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    exit 1
}

Write-Host "`nPress any key to exit..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")