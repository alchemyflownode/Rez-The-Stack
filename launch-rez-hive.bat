@echo off
title REZ HIVE MODEL LAUNCHER 🏛️
color 0A

set "PROJECT_PATH=D:\okiru-os\The Reztack OS"
set "PYTHON_PATH=python"
set "CHROMA_PORT=8000"
set "API_PORT=8001"
set "FRONTEND_PORT=3000"
set "SEARXNG_PORT=8080"

:: Create logs directory if it doesn't exist
if not exist "%PROJECT_PATH%\logs" mkdir "%PROJECT_PATH%\logs"

:menu
cls
echo.
echo  ╔═══════════════════════════════════════════════════════════════╗
echo  ║    🏛️ REZ HIVE - MODEL LAUNCHER (22 MODELS)                  ║
echo  ╚═══════════════════════════════════════════════════════════════╝
echo.
echo  [1] LAUNCH FULL STACK
echo  [2] LAUNCH CHROMADB ONLY
echo  [3] LAUNCH FASTAPI ONLY
echo  [4] LAUNCH NEXT.JS ONLY
echo  [5] LAUNCH SEARXNG (Docker)
echo  [6] LAUNCH MCP SERVERS (WSL)
echo  [7] CHECK STATUS
echo  [8] STOP ALL SERVICES
echo  [9] LIST AVAILABLE MODELS
echo  [0] EXIT
echo.
set /p choice=Select option [0-9]: 

if "%choice%"=="1" goto launch_full
if "%choice%"=="2" goto launch_chroma
if "%choice%"=="3" goto launch_fastapi
if "%choice%"=="4" goto launch_nextjs
if "%choice%"=="5" goto launch_searxng
if "%choice%"=="6" goto launch_mcp
if "%choice%"=="7" goto status
if "%choice%"=="8" goto kill
if "%choice%"=="9" goto list_models
if "%choice%"=="0" exit /b 0
goto menu

:launch_full
cls
echo 🚀 Launching FULL STACK with Model Toggle...
echo.

:: Kill existing processes
taskkill /F /IM python.exe >nul 2>&1
taskkill /F /IM node.exe >nul 2>&1
timeout /t 2 /nobreak >nul

:: 1. ChromaDB
echo [1/4] Starting ChromaDB Memory...
start "ChromaDB" cmd /k "cd /d "%PROJECT_PATH%" && chroma run --path ./chroma_data --port %CHROMA_PORT% >> "%PROJECT_PATH%\logs\chroma.log" 2>&1"
timeout /t 3 /nobreak >nul

:: 2. FastAPI
echo [2/4] Starting FastAPI Backend...
if exist "%PROJECT_PATH%\backend\kernel.py" (
    start "FastAPI" cmd /k "cd /d "%PROJECT_PATH%" && python backend\kernel.py >> "%PROJECT_PATH%\logs\fastapi.log" 2>&1"
) else (
    echo   ⚠️ kernel.py not found - skipping
)
timeout /t 3 /nobreak >nul

:: 3. Next.js
echo [3/4] Starting Next.js Frontend...
if exist "%PROJECT_PATH%\package.json" (
    start "Next.js" cmd /k "cd /d "%PROJECT_PATH%" && npm run dev >> "%PROJECT_PATH%\logs\frontend.log" 2>&1"
) else (
    echo   ⚠️ package.json not found - skipping
)

:: 4. Model info
echo [4/4] Model toggle enabled in UI
echo.
echo ✅ FULL STACK LAUNCHED - Select models from dropdown in UI
echo.
echo 📍 Frontend: http://localhost:%FRONTEND_PORT%
echo 📍 Backend:  http://localhost:%API_PORT%
echo 📍 ChromaDB: http://localhost:%CHROMA_PORT%
echo.
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
echo API Docs at http://localhost:%API_PORT%/docs
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
        echo ❌ Failed to start SearXNG - Is Docker Desktop running?
    )
)
pause
goto menu

:launch_mcp
cls
echo Starting MCP Servers in WSL...
if exist "%PROJECT_PATH%\mcp_servers" (
    echo Killing old MCP processes...
    wsl -d Ubuntu -e bash -c "pkill -f mcp_servers" >nul 2>&1
    
    echo Starting executive_mcp.py...
    start "MCP-Executive" wsl -d Ubuntu bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && python3 mcp_servers/executive_mcp.py"
    
    echo Starting system_mcp.py...
    start "MCP-System" wsl -d Ubuntu bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && python3 mcp_servers/system_mcp.py"
    
    echo Starting process_mcp.py...
    start "MCP-Process" wsl -d Ubuntu bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && python3 mcp_servers/process_mcp.py"
    
    echo Starting research_mcp.py...
    start "MCP-Research" wsl -d Ubuntu bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && python3 mcp_servers/research_mcp.py"
    
    echo Starting rag_pipeline.py...
    start "MCP-RAG" wsl -d Ubuntu bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && python3 mcp_servers/rag_pipeline.py"
    
    echo ✅ All MCP servers started
) else (
    echo ⚠️ MCP servers directory not found
)
pause
goto menu

:status
cls
echo ================================
echo   SERVICE STATUS
echo ================================
echo.

:: Check ports
netstat -ano | findstr ":%FRONTEND_PORT%" | findstr "LISTENING" >nul && echo ✅ Next.js:   RUNNING || echo ❌ Next.js:   OFFLINE
netstat -ano | findstr ":%API_PORT%" | findstr "LISTENING" >nul && echo ✅ FastAPI:   RUNNING || echo ❌ FastAPI:   OFFLINE
netstat -ano | findstr ":%CHROMA_PORT%" | findstr "LISTENING" >nul && echo ✅ ChromaDB:  RUNNING || echo ❌ ChromaDB:  OFFLINE
netstat -ano | findstr ":11434" | findstr "LISTENING" >nul && echo ✅ Ollama:    RUNNING || echo ⚠️ Ollama:    OFFLINE

:: Check Docker
docker ps 2>nul | findstr "searxng" >nul && echo ✅ SearXNG:   RUNNING || echo ⚠️ SearXNG:   OFFLINE

:: Check MCP
wsl -d Ubuntu -e bash -c "pgrep -f mcp_servers" 2>nul | findstr /v "^$" >nul && echo ✅ MCP:       RUNNING || echo ⚠️ MCP:       OFFLINE

echo.
pause
goto menu

:list_models
cls
echo ================================
echo   AVAILABLE OLLAMA MODELS
echo ================================
echo.
ollama list
echo.
echo 📍 Total models: 22
echo.
pause
goto menu

:kill
cls
echo Stopping all services...
taskkill /F /IM python.exe >nul 2>&1
taskkill /F /IM node.exe >nul 2>&1
docker stop searxng >nul 2>&1
wsl -d Ubuntu -e bash -c "pkill -f mcp_servers" >nul 2>&1
echo ✅ All services stopped
pause
goto menu