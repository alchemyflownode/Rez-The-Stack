# quick-fix.ps1 - Clean version with no special characters
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Quick Fix for REZ HIVE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Kill process on port 3000
Write-Host "[1/3] Checking port 3000..." -ForegroundColor Yellow

$processInfo = netstat -ano | findstr :3000 | findstr LISTENING
if ($processInfo) {
    $parts = $processInfo -split '\s+'
    $pidNumber = $parts[-1]
    Write-Host "   Found process using port 3000 (PID: $pidNumber)" -ForegroundColor Yellow
    taskkill /F /PID $pidNumber 2>$null
    Write-Host "   Process killed" -ForegroundColor Green
} else {
    Write-Host "   Port 3000 is free" -ForegroundColor Green
}

Write-Host ""

# Clear Next.js cache
Write-Host "[2/3] Clearing Next.js cache..." -ForegroundColor Yellow
if (Test-Path ".next") {
    Remove-Item -Path ".next" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "   Cache cleared" -ForegroundColor Green
} else {
    Write-Host "   No cache found" -ForegroundColor Green
}

Write-Host ""

# Start Next.js
Write-Host "[3/3] Starting Next.js..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "npm run dev"
Start-Sleep -Seconds 2

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Next.js starting in new window!" -ForegroundColor Green
Write-Host "Access at: http://localhost:3000" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Green