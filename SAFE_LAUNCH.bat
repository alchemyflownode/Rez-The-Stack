Write-Host "⚡ Rez Hive Launcher" -ForegroundColor Cyan
Write-Host "===================="

$projectPath = "D:\okiru-os\The Reztack OS"
Set-Location $projectPath

Write-Host "`n📂 Project Directory: $projectPath" -ForegroundColor Yellow

# Check if files exist
if (Test-Path "backend\kernel.py") {
    Write-Host "✅ Kernel found" -ForegroundColor Green
} else {
    Write-Host "❌ Kernel not found!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

Write-Host "`n📋 Available Commands:" -ForegroundColor Cyan
Write-Host "1. Start Kernel"
Write-Host "2. Start Frontend"
Write-Host "3. Start ChromaDB"
Write-Host "4. Exit"

$choice = Read-Host "`nSelect option"

switch ($choice) {
    "1" { 
        Write-Host "Starting Kernel..." -ForegroundColor Yellow
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$projectPath'; python backend\kernel.py"
    }
    "2" { 
        Write-Host "Starting Frontend..." -ForegroundColor Yellow
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$projectPath'; npm run dev -- -p 3001"
    }
    "3" { 
        Write-Host "Starting ChromaDB..." -ForegroundColor Yellow
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "chroma run --path ./chroma_data --port 8000"
    }
}

Read-Host "`nPress Enter to exit"