# ============================================
# REZ HIVE - SYSTEM AUDIT SCRIPT
# ============================================

$REZ_ROOT = "D:\okiru-os\The Reztack OS"
Set-Location $REZ_ROOT

Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  🔍 REZ HIVE - SYSTEM AUDIT                                  ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$issues = @()

# ============================================
# CHECK 1: CSS IMPORT IN LAYOUT.TSX
# ============================================
Write-Host "[1/4] Checking layout.tsx CSS import..." -ForegroundColor Yellow

$layoutFile = "src\app\layout.tsx"
if (Test-Path $layoutFile) {
    $layout = Get-Content $layoutFile -Raw
    if ($layout -match "import.*\.\/globals\.css") {
        Write-Host "   ✅ globals.css properly imported in layout.tsx" -ForegroundColor Green
    } else {
        Write-Host "   ❌ MISSING: globals.css not imported in layout.tsx" -ForegroundColor Red
        $issues += "❌ globals.css not imported in layout.tsx"
    }
} else {
    Write-Host "   ❌ layout.tsx not found!" -ForegroundColor Red
    $issues += "❌ layout.tsx not found"
}

# ============================================
# CHECK 2: TAILWIND CONFIG PATHS
# ============================================
Write-Host "`n[2/4] Checking tailwind.config.js paths..." -ForegroundColor Yellow

$tailwindConfig = "tailwind.config.js"
if (Test-Path $tailwindConfig) {
    $config = Get-Content $tailwindConfig -Raw
    if ($config -match "\./src/app/\*\*/\*\.\{js,ts,jsx,tsx,mdx\}") {
        Write-Host "   ✅ tailwind.config.js watching src/app" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ WARNING: tailwind.config.js may not be watching src/app" -ForegroundColor Yellow
        $issues += "⚠️ tailwind.config.js may not be watching src/app"
    }
} else {
    Write-Host "   ❌ tailwind.config.js not found!" -ForegroundColor Red
    $issues += "❌ tailwind.config.js not found"
}

# ============================================
# CHECK 3: CSS VARIABLES
# ============================================
Write-Host "`n[3/4] Checking CSS variables..." -ForegroundColor Yellow

$cssFile = "src\app\globals.css"
if (Test-Path $cssFile) {
    $css = Get-Content $cssFile -Raw
    if ($css -match "--hive-accent|--color-hive-accent") {
        Write-Host "   ✅ CSS variables defined" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ WARNING: No hive color variables found" -ForegroundColor Yellow
        $issues += "⚠️ No hive color variables in CSS"
    }
    
    if ($css -match "@tailwind base;") {
        Write-Host "   ✅ Tailwind directives found" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Missing Tailwind directives" -ForegroundColor Red
        $issues += "❌ Missing Tailwind directives in globals.css"
    }
} else {
    Write-Host "   ❌ globals.css not found!" -ForegroundColor Red
    $issues += "❌ globals.css not found"
}

# ============================================
# CHECK 4: GLASS CARD CLASS IN CSS
# ============================================
Write-Host "`n[4/4] Checking glass-card class..." -ForegroundColor Yellow

if (Test-Path $cssFile) {
    $css = Get-Content $cssFile -Raw
    if ($css -match "\.glass-card") {
        Write-Host "   ✅ glass-card class defined in CSS" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ WARNING: glass-card class not found in CSS" -ForegroundColor Yellow
        $issues += "⚠️ glass-card class missing from CSS"
    }
}

# ============================================
# SUMMARY
# ============================================
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  📊 AUDIT SUMMARY                                            ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

if ($issues.Count -eq 0) {
    Write-Host "   ✅ NO ISSUES FOUND! Your CSS should be working!" -ForegroundColor Green
} else {
    Write-Host "   ⚠️ Found $($issues.Count) issues:" -ForegroundColor Yellow
    foreach ($issue in $issues) {
        Write-Host "       $issue" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "🔧 QUICK FIXES:" -ForegroundColor Cyan
    
    if ($issues -match "not imported in layout.tsx") {
        Write-Host "   1. Add this to src/app/layout.tsx:" -ForegroundColor White
        Write-Host '      import "./globals.css";' -ForegroundColor Gray
    }
    
    if ($issues -match "watching src/app") {
        Write-Host "   2. Update tailwind.config.js content array:" -ForegroundColor White
        Write-Host '      content: ["./src/app/**/*.{js,ts,jsx,tsx,mdx}"]' -ForegroundColor Gray
    }
    
    if ($issues -match "No hive color variables") {
        Write-Host "   3. Add to globals.css:" -ForegroundColor White
        Write-Host "      :root { --hive-accent: #00f2ff; }" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "🏛️ Run: npm run dev to see fixes" -ForegroundColor Cyan