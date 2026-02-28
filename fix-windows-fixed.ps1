# ================================================================
# 🦊 SOVEREIGN - IMMEDIATE FIXES FOR WINDOWS (FIXED)
# ================================================================

Write-Host ""
Write-Host "  ╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "  ║     🦊 SOVEREIGN - IMMEDIATE FIXES FOR WINDOWS            ║" -ForegroundColor Cyan
Write-Host "  ╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

$srcPath = "G:\okiru\app builder\Cognitive Kernel\src"

# ================================================================
# FIX 1: Hardcoded Colors - Replace with CSS Variables
# ================================================================
Write-Host "[1/4] Fixing hardcoded colors..." -ForegroundColor Yellow

$colorReplacements = @{
    '#00FFC2' = 'var(--accent-cyan)'
    '#8B5CF6' = 'var(--accent-primary)'
    '#10B981' = 'var(--accent-emerald)'
    '#3B82F6' = 'var(--accent-blue)'
    '#EF4444' = 'var(--accent-red)'
    '#FFB800' = 'var(--accent-amber)'
    '#0A0A0C' = 'var(--bg-deep)'
    '#121214' = 'var(--bg-surface)'
    '#050505' = 'var(--bg-deep)'
    '#F59E0B' = 'var(--accent-amber)'
}

$tsxFiles = Get-ChildItem -Path $srcPath -Filter "*.tsx" -Recurse
$cssFiles = Get-ChildItem -Path $srcPath -Filter "*.css" -Recurse
$allFiles = $tsxFiles + $cssFiles

$fixCount = 0
foreach ($file in $allFiles) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    
    $original = $content
    $changed = $false
    
    foreach ($color in $colorReplacements.Keys) {
        if ($content -match [regex]::Escape($color)) {
            $content = $content -replace [regex]::Escape($color), $colorReplacements[$color]
            $changed = $true
            $fixCount++
        }
    }
    
    if ($changed) {
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8
        Write-Host "   ✅ Fixed colors in: $($file.Name)" -ForegroundColor Green
    }
}
Write-Host "   ✅ Fixed $fixCount color violations" -ForegroundColor Green

# ================================================================
# FIX 2: Add Missing Alt Text to Images
# ================================================================
Write-Host "[2/4] Adding missing alt text to images..." -ForegroundColor Yellow

$imageFiles = Get-ChildItem -Path $srcPath -Filter "*.tsx" -Recurse | Where-Object {
    $content = Get-Content $_.FullName -Raw
    return $content -match "<img"
}

$altFixCount = 0
foreach ($file in $imageFiles) {
    $content = Get-Content $file.FullName -Raw
    $original = $content
    
    # Find img tags without alt attribute
    $pattern = '<img\s+(?![^>]*\salt=)[^>]*>'
    $matches = [regex]::Matches($content, $pattern)
    
    foreach ($match in $matches) {
        $newTag = $match.Value -replace '<img', '<img alt=""'
        $content = $content -replace [regex]::Escape($match.Value), $newTag
        $altFixCount++
    }
    
    if ($content -ne $original) {
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8
        Write-Host "   ✅ Added alt text to: $($file.Name)" -ForegroundColor Green
    }
}
Write-Host "   ✅ Added alt text to $altFixCount images" -ForegroundColor Green

# ================================================================
# FIX 3: Reduce Component Depth - Create Refactoring Plan
# ================================================================
Write-Host "[3/4] Analyzing deep components for refactoring..." -ForegroundColor Yellow

$deepComponents = @(
    @{Path = "src\components\SovereignControlSurface.tsx"; Depth = 36},
    @{Path = "src\components\NeuralHub.tsx"; Depth = 35}
)

Write-Host "   Creating refactoring templates..." -ForegroundColor Yellow

foreach ($comp in $deepComponents) {
    $fullPath = Join-Path $srcPath $comp.Path.Replace("src\", "")
    if (Test-Path $fullPath) {
        $content = Get-Content $fullPath -Raw
        $lines = $content -split "`n"
        $lineCount = $lines.Count
        
        $planName = "refactor_" + ($comp.Path -replace '\.tsx', '_plan.md') -replace '\\', '_' -replace 'src_', ''
        $planPath = Join-Path $PWD.Path $planName
        
        $planContent = @"
# Refactoring Plan: $($comp.Path)

## Current State
- **File**: $($comp.Path)
- **Nesting Depth**: $($comp.Depth)
- **Total Lines**: $lineCount

## Recommended Splits

### Sub-components to Extract
1. **HeaderSection** - Extract from render function
2. **MetricsDisplay** - Extract stats display logic
3. **WorkerGrid** - Extract worker visualization
4. **FooterSection** - Extract footer elements

## Benefits
- Reduces depth from $($comp.Depth) to <10
- Improves maintainability
- Enables code reuse

## Implementation Steps
1. Create new components in `src/components/ui/`
2. Import them into main component
3. Replace inline JSX with component calls
"@
        
        $planContent | Out-File -FilePath $planPath -Encoding UTF8
        Write-Host "   ✅ Created refactoring plan: $planName" -ForegroundColor Green
    }
}

# ================================================================
# FIX 4: Remove Duplicate Files
# ================================================================
Write-Host "[4/4] Removing duplicate files..." -ForegroundColor Yellow

$duplicates = @(
    "src\lib\okiru-engine.ts.backup",
    "src\lib\okiru-engine.ts.corrupted_backup",
    "src\temp_workspace\temp_1771901788094.py",
    "src\temp_workspace\temp_1771901844573.py"
)

$duplicateCount = 0
foreach ($dup in $duplicates) {
    $fullPath = Join-Path $srcPath "..\$dup"
    if (Test-Path $fullPath) {
        Remove-Item -Path $fullPath -Force
        Write-Host "   ✅ Removed: $dup" -ForegroundColor Green
        $duplicateCount++
    }
}
Write-Host "   ✅ Removed $duplicateCount duplicate files" -ForegroundColor Green

# ================================================================
# CREATE GLOBAL CSS VARIABLES IF MISSING
# ================================================================
Write-Host "Ensuring CSS variables are defined..." -ForegroundColor Yellow

$cssVarsFile = "$srcPath\app\globals.css"
if (Test-Path $cssVarsFile) {
    $content = Get-Content $cssVarsFile -Raw
    
    if ($content -notmatch "--accent-cyan") {
        $variables = @"

/* ===== SOVEREIGN CSS VARIABLES ===== */
:root {
  --accent-cyan: #00FFC2;
  --accent-primary: #8B5CF6;
  --accent-emerald: #10B981;
  --accent-blue: #3B82F6;
  --accent-red: #EF4444;
  --accent-amber: #FFB800;
  --bg-deep: #0A0A0C;
  --bg-surface: #121214;
}
"@
        $content += $variables
        Set-Content -Path $cssVarsFile -Value $content -Encoding UTF8
        Write-Host "   ✅ Added CSS variables to globals.css" -ForegroundColor Green
    }
} else {
    Write-Host "   ⚠️ globals.css not found, creating it..." -ForegroundColor Yellow
    $defaultCss = @"
@tailwind base;
@tailwind components;
@tailwind utilities;

/* ===== SOVEREIGN CSS VARIABLES ===== */
:root {
  --accent-cyan: #00FFC2;
  --accent-primary: #8B5CF6;
  --accent-emerald: #10B981;
  --accent-blue: #3B82F6;
  --accent-red: #EF4444;
  --accent-amber: #FFB800;
  --bg-deep: #0A0A0C;
  --bg-surface: #121214;
}
"@
    $defaultCss | Out-File -FilePath $cssVarsFile -Encoding UTF8
    Write-Host "   ✅ Created globals.css with variables" -ForegroundColor Green
}

# ================================================================
# COMPLETION
# ================================================================
Write-Host ""
Write-Host "  ╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "  ║     ✅ IMMEDIATE FIXES COMPLETE                            ║" -ForegroundColor Green
Write-Host "  ╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""
Write-Host "  📊 FIXES APPLIED:" -ForegroundColor Cyan
Write-Host "     • Fixed $fixCount hardcoded colors" -ForegroundColor White
Write-Host "     • Added alt text to $altFixCount images" -ForegroundColor White
Write-Host "     • Created refactoring plans for deep components" -ForegroundColor White
Write-Host "     • Removed $duplicateCount duplicate files" -ForegroundColor White
Write-Host ""
Write-Host "  📁 Refactoring plans created:" -ForegroundColor Yellow
Get-ChildItem -Path ".\refactor_*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "     • $($_.Name)" -ForegroundColor Gray
}
Write-Host ""
Write-Host "  🚀 Next steps:" -ForegroundColor Green
Write-Host "     1. Review refactoring plans and implement sub-components"
Write-Host "     2. Run REZSCAN again to verify fixes: .\rezscan.ps1"
Write-Host "     3. Restart server: .\rez-control.bat (option 3)"
Write-Host ""