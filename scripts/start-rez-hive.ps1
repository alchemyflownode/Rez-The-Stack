Write-Host "Starting REZ HIVE Full Stack..." -ForegroundColor Cyan

$ProjectPath = "D:\okiru-os\The Reztack OS"
Set-Location $ProjectPath

Write-Host "[1/3] Checking Ollama..." -ForegroundColor Yellow
$ollamaRunning = Get-Process ollama -ErrorAction SilentlyContinue
if (-not $ollamaRunning) {
    Start-Process powershell -ArgumentList "-Command", "ollama serve"
    Start-Sleep -Seconds 3
}
Write-Host "   Ollama ready" -ForegroundColor Green

Write-Host "[2/3] Starting Backend..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$ProjectPath'; python backend/kernel.py"
Start-Sleep -Seconds 3
Write-Host "   Backend ready" -ForegroundColor Green

Write-Host "[3/3] Starting Frontend..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$ProjectPath'; npm run dev"
Write-Host "   Frontend ready" -ForegroundColor Green

Write-Host ""
Write-Host "======================================================" -ForegroundColor Green
Write-Host "   REZ HIVE IS RUNNING" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green
Write-Host "Frontend:  http://localhost:3000" -ForegroundColor Cyan
Write-Host "Backend:   http://localhost:8001" -ForegroundColor Cyan
Write-Host "API Docs:  http://localhost:8001/docs" -ForegroundColor Cyan
Write-Host ""
