# restart-fixed.ps1
Write-Host "🏛️ Restarting REZ HIVE with fixed API..." -ForegroundColor Cyan

# Kill existing processes
Write-Host "`n🛑 Stopping services..." -ForegroundColor Yellow
taskkill /F /IM python.exe 2>$null
taskkill /F /IM node.exe 2>$null
Start-Sleep -Seconds 2

# Start kernel
Write-Host "`n🚀 Starting kernel..." -ForegroundColor Yellow
$kernel = Start-Process powershell -WindowStyle Normal -ArgumentList "-NoExit", "-Command", "cd '$PWD'; python backend/kernel.py" -PassThru
Start-Sleep -Seconds 3

# Test kernel
Write-Host "`n📡 Testing kernel..." -ForegroundColor Yellow
try {
    $status = Invoke-RestMethod -Uri "http://localhost:8001/api/status" -ErrorAction Stop
    Write-Host "   ✅ Kernel running" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Kernel failed to start" -ForegroundColor Red
    exit 1
}

# Start frontend
Write-Host "`n🎨 Starting frontend on port 3001..." -ForegroundColor Yellow
$frontend = Start-Process powershell -WindowStyle Normal -ArgumentList "-NoExit", "-Command", "cd '$PWD'; npm run dev -- -p 3001" -PassThru

Write-Host ""
Write-Host "✅ REZ HIVE is running at: http://localhost:3001" -ForegroundColor Green
Write-Host ""
Write-Host "📊 API endpoints:" -ForegroundColor Cyan
Write-Host "   • http://localhost:8001/api/status" -ForegroundColor White
Write-Host "   • http://localhost:8001/kernel/stream (main)" -ForegroundColor White
Write-Host "   • http://localhost:8001/api/kernel (compatibility)" -ForegroundColor White
Write-Host ""
Write-Host "🧪 Test API: .\test-api.ps1" -ForegroundColor Yellow
