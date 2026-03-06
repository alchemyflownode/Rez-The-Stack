# launch-rez-hive-ui.ps1
Write-Host "🏛️ Launching REZ HIVE..." -ForegroundColor Cyan

# Kill existing processes
taskkill /F /IM python.exe 2>$null
taskkill /F /IM node.exe 2>$null

# Start kernel
Write-Host "`n🚀 Starting kernel..." -ForegroundColor Yellow
$kernel = Start-Process powershell -WindowStyle Normal -ArgumentList "-NoExit", "-Command", "cd '$PWD'; python backend/kernel.py" -PassThru
Start-Sleep -Seconds 3

# Start frontend
Write-Host "`n🎨 Starting frontend on port 3001..." -ForegroundColor Yellow
$frontend = Start-Process powershell -WindowStyle Normal -ArgumentList "-NoExit", "-Command", "cd '$PWD'; npm run dev -- -p 3001" -PassThru

Write-Host ""
Write-Host "✅ REZ HIVE is running!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Main UI:    http://localhost:3001" -ForegroundColor Cyan
Write-Host "📊 Chat UI:    http://localhost:3001/rez-hive.html" -ForegroundColor Cyan
Write-Host "📊 Kernel:     http://localhost:8001" -ForegroundColor Gray
