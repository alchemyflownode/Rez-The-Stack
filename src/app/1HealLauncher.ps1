# MANUAL HEALING SEQUENCE (Copy & Paste Entire Block)

Write-Host "🏛️ SOVEREIGN HEALING SEQUENCE INITIATED" -ForegroundColor Magenta

# 1. Kill any hanging processes
Write-Host "`n🔪 Killing stuck processes..." -ForegroundColor Yellow
taskkill /F /IM node.exe 2>$null
taskkill /F /IM python.exe 2>$null
Start-Sleep 2

# 2. Clear ALL caches
Write-Host "`n🧹 Clearing caches..." -ForegroundColor Yellow
Remove-Item -Recurse -Force .next -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force node_modules -ErrorAction SilentlyContinue
Remove-Item -Force package-lock.json -ErrorAction SilentlyContinue

# 3. Install dependencies
Write-Host "`n📦 Installing dependencies..." -ForegroundColor Yellow
npm install

# 4. Verify Next.js is installed
Write-Host "`n✅ Verifying installation..." -ForegroundColor Yellow
if (Test-Path "node_modules/.bin/next") {
    Write-Host "   ✓ Next.js installed" -ForegroundColor Green
} else {
    Write-Host "   ⚠️ Installing Next.js specifically..." -ForegroundColor Yellow
    npm install next@latest react@latest react-dom@latest
}

# 5. Start the app
Write-Host "`n🚀 Starting Next.js..." -ForegroundColor Green
npm run dev

Write-Host "`n📱 Open http://localhost:3001 in your browser" -ForegroundColor Cyan