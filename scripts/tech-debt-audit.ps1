# ============================================
# REZ HIVE - COMPLETE TECHNICAL DEBT AUDIT
# ============================================

$REZ_ROOT = "D:\okiru-os\The Reztack OS"
Set-Location $REZ_ROOT

Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Red
Write-Host "║  📊 REZ HIVE - COMPLETE TECHNICAL DEBT AUDIT                ║" -ForegroundColor Red
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Red
Write-Host ""

# ============================================
# AUDIT 1: DUPLICATE FILES
# ============================================
Write-Host "📁 [1/8] SCANNING FOR DUPLICATE FILES..." -ForegroundColor Cyan

$duplicates = @{}
$allFiles = Get-ChildItem -Path "src" -Recurse -File | Group-Object Name | Where-Object { $_.Count -gt 1 }

if ($allFiles) {
    Write-Host "   ⚠️ Found duplicate files:" -ForegroundColor Yellow
    foreach ($group in $allFiles) {
        Write-Host "       • $($group.Name) ($($group.Count) copies)" -ForegroundColor Gray
        foreach ($file in $group.Group) {
            Write-Host "         - $($file.FullName)" -ForegroundColor DarkGray
        }
    }
} else {
    Write-Host "   ✅ No duplicate files found" -ForegroundColor Green
}

# ============================================
# AUDIT 2: UNUSED DEPENDENCIES
# ============================================
Write-Host "`n📦 [2/8] ANALYZING DEPENDENCIES..." -ForegroundColor Cyan

$packageJson = Get-Content "package.json" -Raw | ConvertFrom-Json
$deps = @{}
$packageJson.dependencies.PSObject.Properties | ForEach-Object { $deps[$_.Name] = "dep" }
$packageJson.devDependencies.PSObject.Properties | ForEach-Object { $deps[$_.Name] = "devDep" }

Write-Host "   Total dependencies: $($deps.Count)" -ForegroundColor White

# Check for unused dependencies
$unusedDeps = @()
foreach ($dep in $deps.Keys) {
    $found = Get-ChildItem -Path "src" -Recurse -File | Select-String -Pattern "import.*$dep|require.*$dep" -ErrorAction SilentlyContinue
    if (-not $found) {
        $unusedDeps += $dep
    }
}

if ($unusedDeps.Count -gt 0) {
    Write-Host "   ⚠️ Potential unused dependencies:" -ForegroundColor Yellow
    $unusedDeps | ForEach-Object { Write-Host "       • $_" -ForegroundColor Gray }
} else {
    Write-Host "   ✅ All dependencies appear to be used" -ForegroundColor Green
}

# ============================================
# AUDIT 3: BACKUP FILES
# ============================================
Write-Host "`n💾 [3/8] SCANNING FOR BACKUP FILES..." -ForegroundColor Cyan

$backups = Get-ChildItem -Path "src" -Recurse -Include "*.bak", "*.backup", "*.old", "*~" -File

if ($backups.Count -gt 0) {
    Write-Host "   ⚠️ Found $($backups.Count) backup files:" -ForegroundColor Yellow
    $backups | ForEach-Object { Write-Host "       • $($_.FullName)" -ForegroundColor Gray }
} else {
    Write-Host "   ✅ No backup files found" -ForegroundColor Green
}

# ============================================
# AUDIT 4: MISSING TYPE DEFINITIONS
# ============================================
Write-Host "`n📝 [4/8] CHECKING FOR MISSING TYPE DEFINITIONS..." -ForegroundColor Cyan

$tsFiles = Get-ChildItem -Path "src" -Recurse -Include "*.ts", "*.tsx" -File
$missingTypes = @()

foreach ($file in $tsFiles) {
    $content = Get-Content $file.FullName -Raw
    # Look for 'any' type usage (potential tech debt)
    if ($content -match ":\s*any\b") {
        $missingTypes += $file.FullName
    }
}

if ($missingTypes.Count -gt 0) {
    Write-Host "   ⚠️ Found $($missingTypes.Count) files using 'any' type:" -ForegroundColor Yellow
    $missingTypes | Select-Object -First 5 | ForEach-Object { Write-Host "       • $_" -ForegroundColor Gray }
    if ($missingTypes.Count -gt 5) { Write-Host "       ... and $($missingTypes.Count - 5) more" -ForegroundColor Gray }
} else {
    Write-Host "   ✅ No 'any' types found (good type coverage)" -ForegroundColor Green
}

# ============================================
# AUDIT 5: LARGE FILES
# ============================================
Write-Host "`n📏 [5/8] CHECKING FOR OVERLY LARGE FILES..." -ForegroundColor Cyan

$largeFiles = Get-ChildItem -Path "src" -Recurse -File | Where-Object { $_.Length -gt 500KB }

if ($largeFiles.Count -gt 0) {
    Write-Host "   ⚠️ Found $($largeFiles.Count) files > 500KB:" -ForegroundColor Yellow
    $largeFiles | Sort-Object Length -Descending | Select-Object -First 5 | ForEach-Object {
        $size = "{0:N2} MB" -f ($_.Length / 1MB)
        Write-Host "       • $($_.Name) - $size" -ForegroundColor Gray
    }
} else {
    Write-Host "   ✅ No files > 500KB" -ForegroundColor Green
}

# ============================================
# AUDIT 6: TODO/FIXME COMMENTS
# ============================================
Write-Host "`n🔍 [6/8] SEARCHING FOR TODO/FIXME COMMENTS..." -ForegroundColor Cyan

$todos = @()
foreach ($file in $tsFiles) {
    $content = Get-Content $file.FullName
    $lines = $content | Select-String -Pattern "TODO|FIXME|HACK|XXX" -CaseSensitive:$false
    foreach ($line in $lines) {
        $todos += "$($file.FullName): $($line.Line.Trim())"
    }
}

if ($todos.Count -gt 0) {
    Write-Host "   ⚠️ Found $($todos.Count) TODO/FIXME comments:" -ForegroundColor Yellow
    $todos | Select-Object -First 5 | ForEach-Object { Write-Host "       • $_" -ForegroundColor Gray }
    if ($todos.Count -gt 5) { Write-Host "       ... and $($todos.Count - 5) more" -ForegroundColor Gray }
} else {
    Write-Host "   ✅ No TODO/FIXME comments found" -ForegroundColor Green
}

# ============================================
# AUDIT 7: CONSOLE.LOG STATEMENTS
# ============================================
Write-Host "`n📢 [7/8] CHECKING FOR CONSOLE.LOG STATEMENTS..." -ForegroundColor Cyan

$consoles = @()
foreach ($file in $tsFiles) {
    $content = Get-Content $file.FullName
    $lines = $content | Select-String -Pattern "console\.log" -CaseSensitive:$false
    foreach ($line in $lines) {
        $consoles += "$($file.FullName): $($line.Line.Trim())"
    }
}

if ($consoles.Count -gt 0) {
    Write-Host "   ⚠️ Found $($consoles.Count) console.log statements:" -ForegroundColor Yellow
    $consoles | Select-Object -First 5 | ForEach-Object { Write-Host "       • $_" -ForegroundColor Gray }
    if ($consoles.Count -gt 5) { Write-Host "       ... and $($consoles.Count - 5) more" -ForegroundColor Gray }
} else {
    Write-Host "   ✅ No console.log statements found" -ForegroundColor Green
}

# ============================================
# AUDIT 8: CSS CONFLICTS
# ============================================
Write-Host "`n🎨 [8/8] CHECKING FOR CSS CONFLICTS..." -ForegroundColor Cyan

$cssFiles = Get-ChildItem -Path "src" -Recurse -Include "*.css" -File
$cssConflicts = @()

foreach ($file in $cssFiles) {
    $content = Get-Content $file.FullName -Raw
    # Look for Tailwind v4 syntax in v3 project
    if ($content -match "spacing\(|theme\(") {
        $cssConflicts += $file.FullName
    }
}

if ($cssConflicts.Count -gt 0) {
    Write-Host "   ⚠️ Found $($cssConflicts.Count) files with Tailwind v4 syntax:" -ForegroundColor Red
    $cssConflicts | ForEach-Object { Write-Host "       • $_" -ForegroundColor Gray }
} else {
    Write-Host "   ✅ No Tailwind v4 syntax found" -ForegroundColor Green
}

# ============================================
# SUMMARY
# ============================================
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Red
Write-Host "║  📊 TECHNICAL DEBT AUDIT SUMMARY                             ║" -ForegroundColor Red
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Red
Write-Host ""

$totalDebt = 0
$debtItems = @()

if ($duplicates.Count -gt 0) { $totalDebt += 5; $debtItems += "Duplicate files: -5" }
if ($unusedDeps.Count -gt 0) { $totalDebt += 10; $debtItems += "Unused dependencies: -10" }
if ($backups.Count -gt 0) { $totalDebt += 3; $debtItems += "Backup files: -3" }
if ($missingTypes.Count -gt 0) { $totalDebt += 8; $debtItems += "Missing type definitions: -8" }
if ($largeFiles.Count -gt 0) { $totalDebt += 5; $debtItems += "Large files: -5" }
if ($todos.Count -gt 0) { $totalDebt += 10; $debtItems += "TODO comments: -10" }
if ($consoles.Count -gt 0) { $totalDebt += 5; $debtItems += "Console.log statements: -5" }
if ($cssConflicts.Count -gt 0) { $totalDebt += 15; $debtItems += "CSS conflicts: -15" }

$healthScore = 100 - $totalDebt
$healthGrade = switch ($healthScore) {
    {$_ -ge 90} { "A" }
    {$_ -ge 80} { "B" }
    {$_ -ge 70} { "C" }
    {$_ -ge 60} { "D" }
    default { "F" }
}

Write-Host "   Project Health Score: $healthScore% (Grade: $healthGrade)" -ForegroundColor $(if ($healthScore -ge 80) { "Green" } elseif ($healthScore -ge 60) { "Yellow" } else { "Red" })
Write-Host ""
Write-Host "   Debt Items:" -ForegroundColor Yellow
foreach ($item in $debtItems) {
    Write-Host "       • $item" -ForegroundColor Gray
}

if ($totalDebt -eq 0) {
    Write-Host "`n   ✅ No technical debt detected! Your project is clean!" -ForegroundColor Green
} else {
    Write-Host "`n   ⚠️ Total technical debt: -$totalDebt points" -ForegroundColor Yellow
    Write-Host "   Recommended actions:" -ForegroundColor Cyan
    if ($duplicates.Count -gt 0) { Write-Host "       • Consolidate duplicate files" -ForegroundColor White }
    if ($unusedDeps.Count -gt 0) { Write-Host "       • Run 'npm uninstall' on unused packages" -ForegroundColor White }
    if ($backups.Count -gt 0) { Write-Host "       • Delete backup files" -ForegroundColor White }
    if ($missingTypes.Count -gt 0) { Write-Host "       • Replace 'any' with proper types" -ForegroundColor White }
    if ($largeFiles.Count -gt 0) { Write-Host "       • Split large files into modules" -ForegroundColor White }
    if ($todos.Count -gt 0) { Write-Host "       • Address TODO/FIXME comments" -ForegroundColor White }
    if ($consoles.Count -gt 0) { Write-Host "       • Remove console.log statements" -ForegroundColor White }
    if ($cssConflicts.Count -gt 0) { Write-Host "       • Fix Tailwind v4/v3 conflicts" -ForegroundColor White }
}

Write-Host ""
Write-Host "🏛️ Audit complete. Run recommended actions to improve health score." -ForegroundColor Cyan