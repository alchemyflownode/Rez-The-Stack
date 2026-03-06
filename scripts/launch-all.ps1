# launch-all.ps1
Write-Host "Launching REZ HIVE Full Stack..." -ForegroundColor Cyan

# Start Docker SearXNG
Write-Host "[1/5] Starting SearXNG..." -ForegroundColor Yellow
docker-compose up -d
Start-Sleep -Seconds 3

# Start ChromaDB
Write-Host "[2/5] Starting ChromaDB..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "python chroma_server.py"

# Start FastAPI
Write-Host "[3/5] Starting FastAPI Kernel..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "python backend/kernel.py"

# Start Next.js
Write-Host "[4/5] Starting Next.js Frontend..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "npm run dev"

Write-Host "[5/5] Services launching..." -ForegroundColor Yellow
Write-Host ""
Write-Host "All services starting!" -ForegroundColor Green
Write-Host "Frontend: http://localhost:3000"
Write-Host "Backend:  http://localhost:8001"
Write-Host "SearXNG:  http://localhost:8080"
