# fix-runtime-error.ps1
Write-Host "🔧 Fixing REZ HIVE Runtime Error..." -ForegroundColor Cyan

$pageFile = "D:\okiru-os\The Reztack OS\src\app\page.tsx"
$content = Get-Content $pageFile -Raw

# Add suppressHydrationWarning to timestamps
$content = $content -replace '(className="text-xs text-white/30 font-mono">){timestamp}', '$1{suppressHydrationWarning}'

# Check for missing imports
if ($content -notmatch "import .+ from 'react'") {
    Write-Host "❌ Missing React import!" -ForegroundColor Red
}

# Check for unescaped quotes in JSX
$content = $content -replace '"', '"'

Set-Content $pageFile $content -Encoding UTF8

Write-Host "✅ Applied fixes" -ForegroundColor Green
Write-Host ""
Write-Host "📋 NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Clear Next.js cache: Remove-Item -Path '.next' -Recurse -Force" -ForegroundColor White
Write-Host "2. Restart server: npm run dev" -ForegroundColor White
Write-Host "3. Check browser console (F12) for specific error" -ForegroundColor White