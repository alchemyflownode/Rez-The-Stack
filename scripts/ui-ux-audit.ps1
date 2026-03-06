# ============================================
# REZ HIVE - COMPLETE UI/UX AUDIT
# ============================================

$REZ_ROOT = "D:\okiru-os\The Reztack OS"
Set-Location $REZ_ROOT

Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  🎨 REZ HIVE - COMPLETE UI/UX AUDIT                         ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$score = 0
$maxScore = 0
$issues = @()

# ============================================
# AUDIT 1: VISUAL HIERARCHY
# ============================================
Write-Host "📊 [1/10] AUDITING VISUAL HIERARCHY..." -ForegroundColor Cyan
$maxScore += 10

$pageContent = Get-Content "src\app\page.tsx" -Raw

# Check for proper heading structure
if ($pageContent -match "<h1|<h2|<h3") {
    Write-Host "   ✅ Proper heading structure found" -ForegroundColor Green
    $score += 3
} else {
    $issues += "❌ Missing proper heading hierarchy"
}

# Check for clear section separation
if ($pageContent -match "grid|flex|gap-|space-y-") {
    Write-Host "   ✅ Clear section separation" -ForegroundColor Green
    $score += 4
} else {
    $issues += "⚠️ Sections may lack clear visual separation"
}

# Check for consistent card styling
if ($pageContent -match "glass-card|metric-card") {
    Write-Host "   ✅ Consistent card styling" -ForegroundColor Green
    $score += 3
} else {
    $issues += "⚠️ Cards may have inconsistent styling"
}

# ============================================
# AUDIT 2: COLOR CONTRAST
# ============================================
Write-Host "`n🎨 [2/10] AUDITING COLOR CONTRAST..." -ForegroundColor Cyan
$maxScore += 10

$cssFiles = Get-ChildItem -Path "src" -Recurse -Include "*.css" -File
$cssContent = ""
foreach ($file in $cssFiles) {
    $cssContent += Get-Content $file.FullName -Raw
}

# Check for sufficient contrast ratios
if ($cssContent -match "color.*#[0-9A-Fa-f]{6}") {
    Write-Host "   ✅ Custom colors defined" -ForegroundColor Green
    $score += 3
}

# Check for text on background contrast
if ($cssContent -match "background.*#.*\n.*color.*#") {
    Write-Host "   ✅ Text/background contrast defined" -ForegroundColor Green
    $score += 4
} else {
    $issues += "⚠️ Text/background contrast may need verification"
}

# Check for accent colors
if ($cssContent -match "accent|--color-hive-") {
    Write-Host "   ✅ Accent color system in place" -ForegroundColor Green
    $score += 3
} else {
    $issues += "⚠️ No accent color system detected"
}

# ============================================
# AUDIT 3: RESPONSIVE DESIGN
# ============================================
Write-Host "`n📱 [3/10] AUDITING RESPONSIVE DESIGN..." -ForegroundColor Cyan
$maxScore += 10

if ($pageContent -match "sm:|md:|lg:|xl:|2xl:") {
    Write-Host "   ✅ Responsive breakpoints found" -ForegroundColor Green
    $score += 5
} else {
    $issues += "❌ No responsive breakpoints detected"
}

if ($pageContent -match "grid-cols-|flex-wrap") {
    Write-Host "   ✅ Flexible layouts detected" -ForegroundColor Green
    $score += 3
} else {
    $issues += "⚠️ Layouts may not be flexible"
}

if ($pageContent -match "hidden\s+(sm:|md:|lg:)") {
    Write-Host "   ✅ Mobile-specific hiding detected" -ForegroundColor Green
    $score += 2
}

# ============================================
# AUDIT 4: INTERACTIVE FEEDBACK
# ============================================
Write-Host "`n👆 [4/10] AUDITING INTERACTIVE FEEDBACK..." -ForegroundColor Cyan
$maxScore += 10

if ($pageContent -match "hover:|focus:|active:") {
    Write-Host "   ✅ Hover/focus states detected" -ForegroundColor Green
    $score += 4
} else {
    $issues += "❌ No hover/focus states found"
}

if ($pageContent -match "transition-|duration-|ease-") {
    Write-Host "   ✅ Smooth transitions detected" -ForegroundColor Green
    $score += 3
} else {
    $issues += "⚠️ No transitions found"
}

if ($pageContent -match "animate-|@keyframes") {
    Write-Host "   ✅ Animations detected" -ForegroundColor Green
    $score += 3
} else {
    $issues += "⚠️ No animations found"
}

# ============================================
# AUDIT 5: LOADING STATES
# ============================================
Write-Host "`n⏳ [5/10] AUDITING LOADING STATES..." -ForegroundColor Cyan
$maxScore += 10

if ($pageContent -match "loading|isLoading|setLoading") {
    Write-Host "   ✅ Loading states detected" -ForegroundColor Green
    $score += 5
} else {
    $issues += "❌ No loading states found"
}

if ($pageContent -match "skeleton|spinner|animate-pulse") {
    Write-Host "   ✅ Visual loading indicators found" -ForegroundColor Green
    $score += 5
} else {
    $issues += "⚠️ No visual loading indicators"
}

# ============================================
# AUDIT 6: ERROR HANDLING
# ============================================
Write-Host "`n❌ [6/10] AUDITING ERROR HANDLING..." -ForegroundColor Cyan
$maxScore += 10

if ($pageContent -match "try\s*\{|catch\s*\(") {
    Write-Host "   ✅ Error handling detected" -ForegroundColor Green
    $score += 5
} else {
    $issues += "❌ No error handling found"
}

if ($pageContent -match "error|setError") {
    Write-Host "   ✅ Error state management detected" -ForegroundColor Green
    $score += 3
}

if ($pageContent -match "ErrorBoundary") {
    Write-Host "   ✅ Error Boundary component found" -ForegroundColor Green
    $score += 2
} else {
    $issues += "⚠️ No Error Boundary detected"
}

# ============================================
# AUDIT 7: ACCESSIBILITY
# ============================================
Write-Host "`n♿ [7/10] AUDITING ACCESSIBILITY..." -ForegroundColor Cyan
$maxScore += 10

if ($pageContent -match "aria-|role=") {
    Write-Host "   ✅ ARIA attributes detected" -ForegroundColor Green
    $score += 4
} else {
    $issues += "❌ No ARIA attributes found"
}

if ($pageContent -match "alt=") {
    Write-Host "   ✅ Image alt text detected" -ForegroundColor Green
    $score += 3
} else {
    $issues += "⚠️ Images may lack alt text"
}

if ($pageContent -match "sr-only") {
    Write-Host "   ✅ Screen reader only text detected" -ForegroundColor Green
    $score += 3
} else {
    $issues += "⚠️ No screen reader optimizations"
}

# ============================================
# AUDIT 8: TYPOGRAPHY
# ============================================
Write-Host "`n📝 [8/10] AUDITING TYPOGRAPHY..." -ForegroundColor Cyan
$maxScore += 10

if ($cssContent -match "font-family.*Inter|JetBrains|Space Grotesk") {
    Write-Host "   ✅ Professional font stack detected" -ForegroundColor Green
    $score += 4
} else {
    $issues += "⚠️ No professional font stack"
}

if ($pageContent -match "text-xs|text-sm|text-base|text-lg|text-xl|text-2xl") {
    Write-Host "   ✅ Typographic scale detected" -ForegroundColor Green
    $score += 3
} else {
    $issues += "⚠️ Inconsistent text sizing"
}

if ($pageContent -match "font-thin|font-light|font-normal|font-medium|font-bold") {
    Write-Host "   ✅ Font weight variations detected" -ForegroundColor Green
    $score += 3
} else {
    $issues += "⚠️ Limited font weight variation"
}

# ============================================
# AUDIT 9: SPACING & LAYOUT
# ============================================
Write-Host "`n📐 [9/10] AUDITING SPACING & LAYOUT..." -ForegroundColor Cyan
$maxScore += 10

if ($pageContent -match "p-\d|px-\d|py-\d|m-\d|mx-\d|my-\d") {
    Write-Host "   ✅ Consistent spacing system detected" -ForegroundColor Green
    $score += 4
} else {
    $issues += "⚠️ Inconsistent spacing"
}

if ($pageContent -match "max-w-|w-full|h-full|min-h-screen") {
    Write-Host "   ✅ Proper container sizing detected" -ForegroundColor Green
    $score += 3
}

if ($pageContent -match "fixed|absolute|relative|sticky") {
    Write-Host "   ✅ Proper positioning strategies" -ForegroundColor Green
    $score += 3
}

# ============================================
# AUDIT 10: USER FEEDBACK
# ============================================
Write-Host "`n💬 [10/10] AUDITING USER FEEDBACK..." -ForegroundColor Cyan
$maxScore += 10

if ($pageContent -match "toast|alert|notification|snackbar") {
    Write-Host "   ✅ User notification system detected" -ForegroundColor Green
    $score += 4
} else {
    $issues += "⚠️ No user notification system"
}

if ($pageContent -match "disabled:|opacity-\d+|cursor-not-allowed") {
    Write-Host "   ✅ Disabled states detected" -ForegroundColor Green
    $score += 3
} else {
    $issues += "⚠️ No disabled state styling"
}

if ($pageContent -match "placeholder:|::placeholder") {
    Write-Host "   ✅ Input placeholder styling detected" -ForegroundColor Green
    $score += 3
}

# ============================================
# SUMMARY
# ============================================
$percentage = [math]::Round(($score / $maxScore) * 100, 1)
$grade = switch ($percentage) {
    {$_ -ge 90} { "A" }
    {$_ -ge 80} { "B" }
    {$_ -ge 70} { "C" }
    {$_ -ge 60} { "D" }
    default { "F" }
}

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  📊 UI/UX AUDIT SUMMARY                                      ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "   Score: $score/$maxScore ($percentage%) - Grade: $grade" -ForegroundColor $(if ($percentage -ge 80) { "Green" } elseif ($percentage -ge 60) { "Yellow" } else { "Red" })
Write-Host ""

if ($issues.Count -gt 0) {
    Write-Host "   🔍 Issues Found:" -ForegroundColor Yellow
    $issues | ForEach-Object { Write-Host "       $_" -ForegroundColor Gray }
} else {
    Write-Host "   ✅ No UI/UX issues detected! Perfect score!" -ForegroundColor Green
}

Write-Host ""
Write-Host "   📋 Recommendations:" -ForegroundColor Cyan

if ($percentage -lt 90) {
    Write-Host "       • Add missing ARIA attributes for accessibility" -ForegroundColor White
    Write-Host "       • Implement proper loading skeletons" -ForegroundColor White
    Write-Host "       • Add hover/focus states to all interactive elements" -ForegroundColor White
    Write-Host "       • Ensure consistent spacing using Tailwind utilities" -ForegroundColor White
    Write-Host "       • Add user notification system (toasts/alerts)" -ForegroundColor White
} else {
    Write-Host "       • Your UI/UX is excellent! Consider A/B testing for further optimization" -ForegroundColor White
    Write-Host "       • Gather user feedback for iterative improvements" -ForegroundColor White
}

Write-Host ""
Write-Host "🏛️ UI/UX Audit Complete" -ForegroundColor Cyan