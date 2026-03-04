# ============================================
# REZ HIVE - COMPLETE SYSTEM LAUNCHER (MODEL TOGGLE)
# ============================================
# This script launches all services:
# 1. ChromaDB (Memory)
# 2. FastAPI (Backend)
# 3. Next.js (Frontend)
# 4. SearXNG (Web Search - Docker)
# 5. MCP Servers (Tools - WSL)
# ============================================

param(
    [switch]$Kill,
    [switch]$Status,
    [switch]$ModelList
)

$PROJECT_PATH = "D:\okiru-os\The Reztack OS"
$PYTHON_PATH = "C:\Users\Zphoenix\AppData\Local\Programs\Python\Python310\python.exe"
$WSL_DISTRO = "Ubuntu"

# ============================================
# ASCII ART HEADER
# ============================================
function Show-Header {
    Clear-Host
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║     🏛️  REZ HIVE - SOVEREIGN AI LAUNCHER (MODEL TOGGLE)       ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================
# KILL ALL SERVICES
# ============================================
if ($Kill) {
    Show-Header
    Write-Host "[1/3] Stopping all REZ HIVE services..." -ForegroundColor Yellow
    
    # Kill Python processes (ChromaDB, FastAPI, MCP)
    Get-Process -Name "python" -ErrorAction SilentlyContinue | Stop-Process -Force
    Get-Process -Name "python3" -ErrorAction SilentlyContinue | Stop-Process -Force
    
    # Kill Node processes (Next.js)
    Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force
    
    # Stop Docker SearXNG
    docker stop searxng 2>$null
    
    # Stop MCP servers in WSL
    wsl -d $WSL_DISTRO -e bash -c "pkill -f mcp_servers" 2>$null
    
    Write-Host "   ✅ All services stopped" -ForegroundColor Green
    exit
}

# ============================================
# SHOW STATUS
# ============================================
if ($Status) {
    Show-Header
    Write-Host "[1/3] Checking service status..." -ForegroundColor Yellow
    
    # Check ChromaDB
    try {
        $chroma = curl.exe -s http://localhost:8000/api/v1/heartbeat
        if ($chroma) {
            Write-Host "   ✅ ChromaDB: Running on port 8000" -ForegroundColor Green
        }
    } catch {
        Write-Host "   ❌ ChromaDB: Not running" -ForegroundColor Red
    }
    
    # Check FastAPI
    try {
        $fastapi = curl.exe -s http://localhost:8001/api/status
        if ($fastapi) {
            Write-Host "   ✅ FastAPI: Running on port 8001" -ForegroundColor Green
        }
    } catch {
        Write-Host "   ❌ FastAPI: Not running" -ForegroundColor Red
    }
    
    # Check Next.js
    try {
        $nextjs = curl.exe -s http://localhost:3000
        if ($nextjs) {
            Write-Host "   ✅ Next.js: Running on port 3000" -ForegroundColor Green
        }
    } catch {
        Write-Host "   ❌ Next.js: Not running" -ForegroundColor Red
    }
    
    # Check Ollama
    try {
        $ollama = curl.exe -s http://localhost:11434/api/tags
        if ($ollama) {
            Write-Host "   ✅ Ollama: Running on port 11434" -ForegroundColor Green
        }
    } catch {
        Write-Host "   ❌ Ollama: Not running" -ForegroundColor Red
    }
    
    # Check SearXNG
    $searxng = docker ps --filter "name=searxng" --format "{{.Status}}" 2>$null
    if ($searxng -match "Up") {
        Write-Host "   ✅ SearXNG: Running on port 8080" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  SearXNG: Not running" -ForegroundColor Yellow
    }
    
    exit
}

# ============================================
# SHOW MODELS
# ============================================
if ($ModelList) {
    Show-Header
    Write-Host "[1/1] Available Ollama Models:" -ForegroundColor Yellow
    Write-Host ""
    ollama list
    Write-Host ""
    Write-Host "📍 Total models: $((ollama list).Count)" -ForegroundColor Cyan
    exit
}

# ============================================
# MAIN LAUNCH SEQUENCE
# ============================================
Show-Header

# Check if we're in the right directory
if (-not (Test-Path $PROJECT_PATH)) {
    Write-Host "❌ ERROR: Project path not found: $PROJECT_PATH" -ForegroundColor Red
    exit 1
}

Set-Location $PROJECT_PATH
Write-Host "📍 Working directory: $PROJECT_PATH" -ForegroundColor Gray
Write-Host ""

# ============================================
# STEP 1: Kill existing processes
# ============================================
Write-Host "[1/6] Cleaning up existing processes..." -ForegroundColor Yellow
Get-Process -Name "python" -ErrorAction SilentlyContinue | Stop-Process -Force 2>$null
Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force 2>$null
wsl -d $WSL_DISTRO -e bash -c "pkill -f mcp_servers" 2>$null
Start-Sleep -Seconds 2
Write-Host "   ✅ Cleanup complete" -ForegroundColor Green
Write-Host ""

# ============================================
# STEP 2: Start ChromaDB (Memory)
# ============================================
Write-Host "[2/6] Starting ChromaDB Memory Server..." -ForegroundColor Yellow

# Use direct chroma command (better than custom script)
Start-Process powershell -WindowStyle Normal -ArgumentList "-NoExit", "-Command", "cd '$PROJECT_PATH'; chroma run --path ./chroma_data --port 8000"
Start-Sleep -Seconds 5
Write-Host "   ✅ ChromaDB starting in new window" -ForegroundColor Green
Write-Host ""

# ============================================
# STEP 3: Start FastAPI (Backend)
# ============================================
Write-Host "[3/6] Starting FastAPI Backend..." -ForegroundColor Yellow

# Check if backend exists
if (-not (Test-Path "backend\kernel.py")) {
    Write-Host "   ❌ ERROR: backend\kernel.py not found!" -ForegroundColor Red
    exit 1
}

# Start FastAPI in new window
Start-Process powershell -WindowStyle Normal -ArgumentList "-NoExit", "-Command", "cd '$PROJECT_PATH'; python backend/kernel.py"
Start-Sleep -Seconds 5
Write-Host "   ✅ FastAPI starting in new window" -ForegroundColor Green
Write-Host ""

# ============================================
# STEP 4: Start Next.js (Frontend)
# ============================================
Write-Host "[4/6] Starting Next.js Frontend..." -ForegroundColor Yellow

# Start Next.js in new window
Start-Process powershell -WindowStyle Normal -ArgumentList "-NoExit", "-Command", "cd '$PROJECT_PATH'; npm run dev"
Start-Sleep -Seconds 2
Write-Host "   ✅ Next.js starting in new window" -ForegroundColor Green
Write-Host ""

# ============================================
# STEP 5: Start SearXNG (Web Search)
# ============================================
Write-Host "[5/6] Starting SearXNG Web Search..." -ForegroundColor Yellow

# Check if Docker is running
$dockerRunning = docker ps 2>$null
if ($dockerRunning) {
    # Start or create SearXNG container
    $searxngExists = docker ps -a --filter "name=searxng" --format "{{.Names}}" 2>$null
    if ($searxngExists -eq "searxng") {
        docker start searxng 2>$null
        Write-Host "   ✅ SearXNG started (existing container)" -ForegroundColor Green
    } else {
        docker run -d --name searxng -p 8080:8080 searxng/searxng:latest 2>$null
        Write-Host "   ✅ SearXNG created and started" -ForegroundColor Green
    }
} else {
    Write-Host "   ⚠️  Docker not running - SearXNG skipped" -ForegroundColor Yellow
}
Write-Host ""

# ============================================
# STEP 6: Start MCP Servers (in WSL)
# ============================================
Write-Host "[6/6] Starting MCP Servers in WSL..." -ForegroundColor Yellow

# Check if MCP directory exists
if (Test-Path "mcp_servers") {
    # Kill any existing MCP processes
    wsl -d $WSL_DISTRO -e bash -c "pkill -f mcp_servers" 2>$null
    
    # Start each MCP server
    $mcpServers = @("executive", "system", "process", "research", "rag")
    foreach ($server in $mcpServers) {
        $scriptPath = "mcp_servers/${server}_mcp.py"
        if (Test-Path $scriptPath) {
            Start-Process wsl -WindowStyle Hidden -ArgumentList "-d", $WSL_DISTRO, "bash", "-c", "cd /mnt/d/okiru-os/The\ Reztack\ OS && python3 $scriptPath"
            Write-Host "   ✅ Started: ${server}_mcp.py" -ForegroundColor Green
        }
    }
} else {
    Write-Host "   ⚠️  MCP servers directory not found - skipping" -ForegroundColor Yellow
}
Write-Host ""

# ============================================
# VERIFY SERVICES
# ============================================
Write-Host "[Verifying services..." -ForegroundColor Yellow
Start-Sleep -Seconds 8

$allGood = $true

# Test ChromaDB
try {
    $chroma = curl.exe -s http://localhost:8000/api/v1/heartbeat
    if ($chroma) {
        Write-Host "   ✅ ChromaDB: Running" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  ChromaDB: Not responding yet" -ForegroundColor Yellow
        $allGood = $false
    }
} catch {
    Write-Host "   ⚠️  ChromaDB: Not responding yet" -ForegroundColor Yellow
    $allGood = $false
}

# Test FastAPI
try {
    $fastapi = curl.exe -s http://localhost:8001/api/status
    if ($fastapi) {
        Write-Host "   ✅ FastAPI: Running" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  FastAPI: Not responding yet" -ForegroundColor Yellow
        $allGood = $false
    }
} catch {
    Write-Host "   ⚠️  FastAPI: Not responding yet" -ForegroundColor Yellow
    $allGood = $false
}

# ============================================
# LAUNCH SUMMARY
# ============================================
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║     ✅ REZ HIVE LAUNCH SEQUENCE COMPLETE                      ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Host "📍 ACCESS POINTS:" -ForegroundColor White
Write-Host "   • Frontend UI:  http://localhost:3000" -ForegroundColor Cyan
Write-Host "   • Backend API:  http://localhost:8001" -ForegroundColor Cyan
Write-Host "   • API Docs:     http://localhost:8001/docs" -ForegroundColor Cyan
Write-Host "   • ChromaDB:     http://localhost:8000" -ForegroundColor Cyan
Write-Host "   • SearXNG:      http://localhost:8080" -ForegroundColor Cyan
Write-Host "   • Ollama:       http://localhost:11434" -ForegroundColor Cyan
Write-Host ""

Write-Host "🎮 NEW FEATURE: Model Toggle in UI header!" -ForegroundColor Magenta
Write-Host "   Click the model dropdown next to Memory indicator" -ForegroundColor White
Write-Host ""

Write-Host "🛠️  USEFUL COMMANDS:" -ForegroundColor White
Write-Host "   • Check status:  .\launch-rez-hive.ps1 -Status" -ForegroundColor Yellow
Write-Host "   • List models:    .\launch-rez-hive.ps1 -ModelList" -ForegroundColor Yellow
Write-Host "   • Kill all:       .\launch-rez-hive.ps1 -Kill" -ForegroundColor Yellow
Write-Host ""

Write-Host "🏛️  REZ HIVE WITH MODEL TOGGLE IS READY!" -ForegroundColor Green
Write-Host ""