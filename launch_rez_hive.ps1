# PowerShell launcher - less likely to be blocked
Write-Host "⚡ Rez Hive Launcher" -ForegroundColor Cyan

$projectPath = "D:\okiru-os\The Reztack OS"
$logFile = "$projectPath\launch_log.txt"

"$(Get-Date) - Launch started" | Out-File $logFile

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "⚠️ Not running as Administrator" -ForegroundColor Yellow
    Write-Host "Some features may not work. Continue? (y/n)" -ForegroundColor Yellow
    $continue = Read-Host
    if ($continue -ne "y") { exit }
}

Write-Host "`n📋 Available Commands:" -ForegroundColor Green
Write-Host "1. Start Kernel"
Write-Host "2. Start Frontend"
Write-Host "3. Start ChromaDB"
Write-Host "4. Start ALL"
Write-Host "5. Show Status"
Write-Host "6. Exit"

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
    "4" {
        Write-Host "Starting ALL services..." -ForegroundColor Yellow
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$projectPath'; python backend\kernel.py"
        Start-Sleep 2
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$projectPath'; npm run dev -- -p 3001"
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "chroma run --path ./chroma_data --port 8000"
    }
    "5" {
        Write-Host "`nChecking services..." -ForegroundColor Cyan
        
        # Test Kernel
        try {
            $kernel = Invoke-WebRequest -Uri "http://localhost:8001/health" -TimeoutSec 2 -ErrorAction Stop
            Write-Host "✅ Kernel: Running" -ForegroundColor Green
        } catch {
            Write-Host "❌ Kernel: Not running" -ForegroundColor Red
        }
        
        # Test ChromaDB
        try {
            $chroma = Invoke-WebRequest -Uri "http://localhost:8000/api/v1/heartbeat" -TimeoutSec 2 -ErrorAction Stop
            Write-Host "✅ ChromaDB: Running" -ForegroundColor Green
        } catch {
            Write-Host "❌ ChromaDB: Not running" -ForegroundColor Red
        }
        
        # Test Frontend
        try {
            $frontend = Invoke-WebRequest -Uri "http://localhost:3001" -TimeoutSec 2 -ErrorAction Stop
            Write-Host "✅ Frontend: Running" -ForegroundColor Green
        } catch {
            Write-Host "❌ Frontend: Not running" -ForegroundColor Red
        }
    }
}

Read-Host "`nPress Enter to exit"