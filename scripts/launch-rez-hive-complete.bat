@echo off
title REZ HIVE COMPLETE LAUNCHER 🏛️
color 0A

set "PROJECT_PATH=D:\okiru-os\The Reztack OS"
set "PYTHON_PATH=python"
set "CHROMA_PORT=8000"
set "API_PORT=8001"
set "FRONTEND_PORT=3000"
set "SEARXNG_PORT=8080"
set "WSL_DISTRO=Ubuntu"
set "LOGS_PATH=%PROJECT_PATH%\logs"

:: Create logs directory
if not exist "%LOGS_PATH%" mkdir "%LOGS_PATH%"

:menu
cls
echo.
echo  ╔═══════════════════════════════════════════════════════════════╗
echo  ║    🏛️ REZ HIVE - COMPLETE LAUNCHER (ALL SERVICES)            ║
echo  ╚═══════════════════════════════════════════════════════════════╝
echo.
echo  [1] LAUNCH EVERYTHING (ChromaDB + FastAPI + Next.js + SearXNG + MCP)
echo  [2] LAUNCH BASIC STACK (ChromaDB + FastAPI + Next.js only)
echo  [3] LAUNCH CHROMADB ONLY
echo  [4] LAUNCH FASTAPI ONLY
echo  [5] LAUNCH NEXT.JS ONLY
echo  [6] LAUNCH SEARXNG ONLY
echo  [7] LAUNCH MCP SERVERS ONLY
echo  [8] CHECK STATUS (ALL SERVICES)
echo  [9] STOP ALL SERVICES
echo  [10] LIST AVAILABLE MODELS
echo  [0] EXIT
echo.
set /p choice=Select option [0-10]: 

if "%choice%"=="1" goto launch_everything
if "%choice%"=="2" goto launch_basic
if "%choice%"=="3" goto launch_chroma
if "%choice%"=="4" goto launch_fastapi
if "%choice%"=="5" goto launch_nextjs
if "%choice%"=="6" goto launch_searxng
if "%choice%"=="7" goto launch_mcp
if "%choice%"=="8" goto status
if "%choice%"=="9" goto kill
if "%choice%"=="10" goto list_models
if "%choice%"=="0" exit /b 0
goto menu

:launch_everything
cls
echo 🚀 Launching EVERYTHING - Full Sovereign Stack...
echo.

:: Kill existing processes
echo [1/6] Cleaning up existing processes...
taskkill /F /IM python.exe >nul 2>&1
taskkill /F /IM node.exe >nul 2>&1
wsl -d %WSL_DISTRO% -e bash -c "pkill -f mcp_servers" >nul 2>&1
docker stop searxng >nul 2>&1
timeout /t 2 /nobreak >nul
echo   ✅ Cleanup complete
echo.

:: 1. ChromaDB
echo [2/6] Starting ChromaDB Memory...
if not exist "%PROJECT_PATH%\chroma_data" mkdir "%PROJECT_PATH%\chroma_data"
start "ChromaDB" cmd /k "cd /d "%PROJECT_PATH%" && chroma run --path ./chroma_data --port %CHROMA_PORT% >> "%LOGS_PATH%\chroma.log" 2>&1"
timeout /t 3 /nobreak >nul
echo   ✅ ChromaDB starting
echo.

:: 2. FastAPI
echo [3/6] Starting FastAPI Backend...
if exist "%PROJECT_PATH%\backend\kernel.py" (
    start "FastAPI" cmd /k "cd /d "%PROJECT_PATH%" && python backend\kernel.py >> "%LOGS_PATH%\fastapi.log" 2>&1"
    echo   ✅ FastAPI starting
) else (
    echo   ⚠️ kernel.py not found - skipping
)
timeout /t 3 /nobreak >nul
echo.

:: 3. Next.js
echo [4/6] Starting Next.js Frontend...
if exist "%PROJECT_PATH%\package.json" (
    start "Next.js" cmd /k "cd /d "%PROJECT_PATH%" && npm run dev >> "%LOGS_PATH%\frontend.log" 2>&1"
    echo   ✅ Next.js starting
) else (
    echo   ⚠️ package.json not found - skipping
)
timeout /t 3 /nobreak >nul
echo.

:: 4. SearXNG
echo [5/6] Starting SearXNG Web Search...
docker start searxng >nul 2>&1
if %errorlevel%==0 (
    echo   ✅ SearXNG started (existing container)
) else (
    echo   Creating new SearXNG container...
    docker run -d --name searxng -p %SEARXNG_PORT%:8080 searxng/searxng:latest >nul 2>&1
    if %errorlevel%==0 (
        echo   ✅ SearXNG created and started
    ) else (
        echo   ⚠️ SearXNG failed - Is Docker Desktop running with WSL2?
    )
)
echo.

:: 5. MCP Servers
echo [6/6] Starting MCP Servers in WSL...
if exist "%PROJECT_PATH%\mcp_servers" (
    echo   Killing old MCP processes...
    wsl -d %WSL_DISTRO% -e bash -c "pkill -f mcp_servers" >nul 2>&1
    
    echo   Starting executive_mcp.py...
    start "MCP-Executive" wsl -d %WSL_DISTRO% bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && python3 mcp_servers/executive_mcp.py >> /mnt/d/okiru-os/The\ Reztack\ OS/logs/mcp_exec.log 2>&1"
    timeout /t 1 /nobreak >nul
    
    echo   Starting system_mcp.py...
    start "MCP-System" wsl -d %WSL_DISTRO% bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && python3 mcp_servers/system_mcp.py >> /mnt/d/okiru-os/The\ Reztack\ OS/logs/mcp_system.log 2>&1"
    timeout /t 1 /nobreak >nul
    
    echo   Starting process_mcp.py...
    start "MCP-Process" wsl -d %WSL_DISTRO% bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && python3 mcp_servers/process_mcp.py >> /mnt/d/okiru-os/The\ Reztack\ OS/logs/mcp_process.log 2>&1"
    timeout /t 1 /nobreak >nul
    
    echo   Starting research_mcp.py...
    start "MCP-Research" wsl -d %WSL_DISTRO% bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && python3 mcp_servers/research_mcp.py >> /mnt/d/okiru-os/The\ Reztack\ OS/logs/mcp_research.log 2>&1"
    timeout /t 1 /nobreak >nul
    
    echo   Starting rag_pipeline.py...
    start "MCP-RAG" wsl -d %WSL_DISTRO% bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && python3 mcp_servers/rag_pipeline.py >> /mnt/d/okiru-os/The\ Reztack\ OS/logs/mcp_rag.log 2>&1"
    
    echo   ✅ All MCP servers started
) else (
    echo   ⚠️ MCP servers directory not found
)
echo.

echo ========================================
echo ✅ EVERYTHING LAUNCHED!
echo ========================================
echo.
echo 📍 Frontend:    http://localhost:%FRONTEND_PORT%
echo 📍 Backend API: http://localhost:%API_PORT%
echo 📍 API Docs:    http://localhost:%API_PORT%/docs
echo 📍 ChromaDB:    http://localhost:%CHROMA_PORT%
echo 📍 SearXNG:     http://localhost:%SEARXNG_PORT%
echo.
echo 📁 Logs: %LOGS_PATH%
echo.
echo 🎮 Model toggle in UI header next to Memory indicator
echo.
pause
goto menu

:launch_basic
cls
echo 🚀 Launching BASIC Stack (ChromaDB + FastAPI + Next.js)...
echo.

:: Kill existing processes
taskkill /F /IM python.exe >nul 2>&1
taskkill /F /IM node.exe >nul 2>&1
timeout /t 2 /nobreak >nul

:: ChromaDB
echo [1/3] Starting ChromaDB Memory...
if not exist "%PROJECT_PATH%\chroma_data" mkdir "%PROJECT_PATH%\chroma_data"
start "ChromaDB" cmd /k "cd /d "%PROJECT_PATH%" && chroma run --path ./chroma_data --port %CHROMA_PORT%"
timeout /t 3 /nobreak >nul

:: FastAPI
echo [2/3] Starting FastAPI Backend...
start "FastAPI" cmd /k "cd /d "%PROJECT_PATH%" && python backend\kernel.py"
timeout /t 3 /nobreak >nul

:: Next.js
echo [3/3] Starting Next.js Frontend...
start "Next.js" cmd /k "cd /d "%PROJECT_PATH%" && npm run dev"

echo.
echo ✅ BASIC STACK LAUNCHED
echo 📍 Frontend: http://localhost:%FRONTEND_PORT%
pause
goto menu

:launch_chroma
cls
echo Starting ChromaDB Memory Server...
if not exist "%PROJECT_PATH%\chroma_data" mkdir "%PROJECT_PATH%\chroma_data"
start "ChromaDB" cmd /k "cd /d "%PROJECT_PATH%" && chroma run --path ./chroma_data --port %CHROMA_PORT%"
echo ChromaDB running at http://localhost:%CHROMA_PORT%
pause
goto menu

:launch_fastapi
cls
echo Starting FastAPI Backend...
if not exist "%PROJECT_PATH%\backend\kernel.py" (
    echo ERROR: kernel.py not found
    pause
    goto menu
)
start "FastAPI" cmd /k "cd /d "%PROJECT_PATH%" && python backend\kernel.py"
echo FastAPI running at http://localhost:%API_PORT%
pause
goto menu

:launch_nextjs
cls
echo Starting Next.js Frontend...
if not exist "%PROJECT_PATH%\package.json" (
    echo ERROR: package.json not found
    pause
    goto menu
)
start "Next.js" cmd /k "cd /d "%PROJECT_PATH%" && npm run dev"
echo Next.js running at http://localhost:%FRONTEND_PORT%
pause
goto menu

:launch_searxng
cls
echo Starting SearXNG Web Search...
docker start searxng >nul 2>&1
if %errorlevel%==0 (
    echo ✅ SearXNG running at http://localhost:%SEARXNG_PORT%
) else (
    echo Creating new SearXNG container...
    docker run -d --name searxng -p %SEARXNG_PORT%:8080 searxng/searxng:latest
    if %errorlevel%==0 (
        echo ✅ SearXNG created and running
    ) else (
        echo ❌ Failed - Is Docker Desktop running with WSL2 integration?
    )
)
pause
goto menu

:launch_mcp
cls
echo Starting MCP Servers in WSL...
if exist "%PROJECT_PATH%\mcp_servers" (
    echo Killing old MCP processes...
    wsl -d %WSL_DISTRO% -e bash -c "pkill -f mcp_servers" >nul 2>&1
    
    echo Starting executive_mcp.py...
    start "MCP-Executive" wsl -d %WSL_DISTRO% bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && python3 mcp_servers/executive_mcp.py"
    
    echo Starting system_mcp.py...
    start "MCP-System" wsl -d %WSL_DISTRO% bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && python3 mcp_servers/system_mcp.py"
    
    echo Starting process_mcp.py...
    start "MCP-Process" wsl -d %WSL_DISTRO% bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && python3 mcp_servers/process_mcp.py"
    
    echo Starting research_mcp.py...
    start "MCP-Research" wsl -d %WSL_DISTRO% bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && python3 mcp_servers/research_mcp.py"
    
    echo Starting rag_pipeline.py...
    start "MCP-RAG" wsl -d %WSL_DISTRO% bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && python3 mcp_servers/rag_pipeline.py"
    
    echo ✅ All MCP servers started
) else (
    echo ❌ MCP servers directory not found at: %PROJECT_PATH%\mcp_servers
    dir "%PROJECT_PATH%" | findstr "mcp"
)
pause
goto menu

:status
cls
echo ========================================
echo   COMPLETE SERVICE STATUS
echo ========================================
echo.

:: Check ports
netstat -ano | findstr ":%FRONTEND_PORT%" | findstr "LISTENING" >nul && echo ✅ Next.js:   RUNNING || echo ❌ Next.js:   OFFLINE
netstat -ano | findstr ":%API_PORT%" | findstr "LISTENING" >nul && echo ✅ FastAPI:   RUNNING || echo ❌ FastAPI:   OFFLINE
netstat -ano | findstr ":%CHROMA_PORT%" | findstr "LISTENING" >nul && echo ✅ ChromaDB:  RUNNING || echo ❌ ChromaDB:  OFFLINE
netstat -ano | findstr ":11434" | findstr "LISTENING" >nul && echo ✅ Ollama:    RUNNING || echo ⚠️ Ollama:    OFFLINE

:: Check Docker
docker ps 2>nul | findstr "searxng" >nul && echo ✅ SearXNG:   RUNNING || echo ⚠️ SearXNG:   OFFLINE

:: Check MCP
wsl -d %WSL_DISTRO% -e bash -c "pgrep -f mcp_servers" 2>nul | findstr /v "^$" >nul && echo ✅ MCP:       RUNNING || echo ⚠️ MCP:       OFFLINE

echo.
pause
goto menu

:list_models
cls
echo ========================================
echo   AVAILABLE OLLAMA MODELS
echo ========================================
echo.
ollama list
echo.
echo 📍 Total models: 22
echo.
pause
goto menu

:kill
cls
echo Stopping ALL services...
taskkill /F /IM python.exe >nul 2>&1
taskkill /F /IM node.exe >nul 2>&1
docker stop searxng >nul 2>&1
wsl -d %WSL_DISTRO% -e bash -c "pkill -f mcp_servers" >nul 2>&1
echo ✅ All services stopped
pause
goto menu