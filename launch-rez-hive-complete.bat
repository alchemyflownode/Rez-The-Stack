@echo off
title REZ HIVE COMPLETE LAUNCHER
color 0A

set "PROJECT_PATH=D:\okiru-os\The Reztack OS"
set "PYTHON_PATH=python"
set "CHROMA_PORT=8000"
set "API_PORT=8001"
set "FRONTEND_PORT=3000"
set "FRONTEND_PORT_ALT=3001"
set "SEARXNG_PORT=8080"
set "WSL_DISTRO=Ubuntu"
set "LOGS_PATH=%PROJECT_PATH%\logs"

:: Create logs directory
if not exist "%LOGS_PATH%" mkdir "%LOGS_PATH%"

:menu
cls
echo ===================================================
echo     REZ HIVE - COMPLETE LAUNCHER (ALL SERVICES)
echo ===================================================
echo.
echo  [1] LAUNCH EVERYTHING (Port 3000)
echo  [2] LAUNCH EVERYTHING (Port 3001 - Use if 3000 is busy)
echo  [3] LAUNCH BASIC STACK (Port 3000)
echo  [4] LAUNCH BASIC STACK (Port 3001)
echo  [5] LAUNCH CHROMADB ONLY
echo  [6] LAUNCH FASTAPI ONLY
echo  [7] LAUNCH NEXT.JS ONLY (Port 3000)
echo  [8] LAUNCH NEXT.JS ONLY (Port 3001)
echo  [9] LAUNCH SEARXNG ONLY
echo  [10] LAUNCH MCP SERVERS ONLY
echo  [11] CHECK STATUS (ALL SERVICES)
echo  [12] STOP ALL SERVICES
echo  [13] LIST AVAILABLE MODELS
echo  [14] VIEW LIVE LOGS
echo  [0] EXIT
echo.
set /p choice=Select option [0-14]: 

if "%choice%"=="1" goto launch_everything_3000
if "%choice%"=="2" goto launch_everything_3001
if "%choice%"=="3" goto launch_basic_3000
if "%choice%"=="4" goto launch_basic_3001
if "%choice%"=="5" goto launch_chroma
if "%choice%"=="6" goto launch_fastapi
if "%choice%"=="7" goto launch_nextjs_3000
if "%choice%"=="8" goto launch_nextjs_3001
if "%choice%"=="9" goto launch_searxng
if "%choice%"=="10" goto launch_mcp
if "%choice%"=="11" goto status
if "%choice%"=="12" goto kill
if "%choice%"=="13" goto list_models
if "%choice%"=="14" goto view_logs
if "%choice%"=="0" exit /b 0
goto menu

:launch_everything_3000
set "FRONTEND_PORT=3000"
goto launch_everything

:launch_everything_3001
set "FRONTEND_PORT=3001"
goto launch_everything

:launch_basic_3000
set "FRONTEND_PORT=3000"
goto launch_basic

:launch_basic_3001
set "FRONTEND_PORT=3001"
goto launch_basic

:launch_nextjs_3000
set "FRONTEND_PORT=3000"
goto launch_nextjs

:launch_nextjs_3001
set "FRONTEND_PORT=3001"
goto launch_nextjs

:launch_everything
cls
echo ===================================================
echo LAUNCHING EVERYTHING - VISIBLE OUTPUT (Port %FRONTEND_PORT%)
echo ===================================================
echo.

:: Kill existing processes
echo [1/6] Cleaning up existing processes...
taskkill /F /IM python.exe >nul 2>&1
taskkill /F /IM node.exe >nul 2>&1
wsl -d %WSL_DISTRO% -e bash -c "pkill -f mcp_servers" >nul 2>&1
docker stop searxng >nul 2>&1
timeout /t 2 /nobreak >nul
echo   [OK] Cleanup complete
echo.

:: 1. ChromaDB - VISIBLE output
echo [2/6] Starting ChromaDB Memory (visible window)...
if not exist "%PROJECT_PATH%\chroma_data" mkdir "%PROJECT_PATH%\chroma_data"
start "ChromaDB" cmd /k "cd /d "%PROJECT_PATH%" && echo [CHROMADB] Running on port %CHROMA_PORT% && echo. && chroma run --path ./chroma_data --port %CHROMA_PORT%"
timeout /t 3 /nobreak >nul
echo   [OK] ChromaDB window opened
echo.

:: 2. FastAPI - VISIBLE output
echo [3/6] Starting FastAPI Backend (visible window)...
if exist "%PROJECT_PATH%\backend\kernel.py" (
    start "FastAPI" cmd /k "cd /d "%PROJECT_PATH%" && echo [FASTAPI] Starting on port %API_PORT% && echo. && python backend\kernel.py"
    echo   [OK] FastAPI window opened
) else (
    echo   [WARN] kernel.py not found - skipping
)
timeout /t 3 /nobreak >nul
echo.

:: 3. Next.js - VISIBLE output on selected port
echo [4/6] Starting Next.js Frontend on port %FRONTEND_PORT% (visible window)...
if exist "%PROJECT_PATH%\package.json" (
    start "Next.js" cmd /k "cd /d "%PROJECT_PATH%" && echo [NEXT.JS] Starting on port %FRONTEND_PORT% && echo. && npm run dev -- -p %FRONTEND_PORT%"
    echo   [OK] Next.js window opened on port %FRONTEND_PORT%
) else (
    echo   [WARN] package.json not found - skipping
)
timeout /t 3 /nobreak >nul
echo.

:: 4. SearXNG
echo [5/6] Starting SearXNG Web Search...
docker start searxng >nul 2>&1
if %errorlevel%==0 (
    echo   [OK] SearXNG started (existing container)
) else (
    echo   Creating new SearXNG container...
    docker run -d --name searxng -p %SEARXNG_PORT%:8080 searxng/searxng:latest >nul 2>&1
    if %errorlevel%==0 (
        echo   [OK] SearXNG created and started
    ) else (
        echo   [WARN] SearXNG failed - Is Docker Desktop running?
    )
)
echo.

:: 5. MCP Servers
echo [6/6] Starting MCP Servers in WSL...
if exist "%PROJECT_PATH%\mcp_servers" (
    echo   Killing old MCP processes...
    wsl -d %WSL_DISTRO% -e bash -c "pkill -f mcp_servers" >nul 2>&1
    
    echo   Starting executive_mcp.py (visible)...
    start "MCP-Executive" wsl -d %WSL_DISTRO% bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && echo '[MCP-EXEC] Starting...' && python3 mcp_servers/executive_mcp.py"
    timeout /t 1 /nobreak >nul
    
    echo   Starting system_mcp.py (visible)...
    start "MCP-System" wsl -d %WSL_DISTRO% bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && echo '[MCP-SYS] Starting...' && python3 mcp_servers/system_mcp.py"
    timeout /t 1 /nobreak >nul
    
    echo   Starting process_mcp.py (visible)...
    start "MCP-Process" wsl -d %WSL_DISTRO% bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && echo '[MCP-PROC] Starting...' && python3 mcp_servers/process_mcp.py"
    timeout /t 1 /nobreak >nul
    
    echo   Starting research_mcp.py (visible)...
    start "MCP-Research" wsl -d %WSL_DISTRO% bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && echo '[MCP-RESEARCH] Starting...' && python3 mcp_servers/research_mcp.py"
    timeout /t 1 /nobreak >nul
    
    echo   Starting rag_pipeline.py (visible)...
    start "MCP-RAG" wsl -d %WSL_DISTRO% bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && echo '[MCP-RAG] Starting...' && python3 mcp_servers/rag_pipeline.py"
    
    echo   [OK] All MCP servers started - Check their windows
) else (
    echo   [WARN] MCP servers directory not found
)
echo.

echo ===================================================
echo EVERYTHING LAUNCHED on port %FRONTEND_PORT%!
echo ===================================================
echo.
echo LOOK FOR THESE WINDOWS:
echo - ChromaDB (port 8000)
echo - FastAPI (port 8001)
echo - Next.js (port %FRONTEND_PORT%)
echo - MCP-Executive, MCP-System, MCP-Process, etc.
echo.
echo Frontend:    http://localhost:%FRONTEND_PORT%
echo Backend API: http://localhost:%API_PORT%
echo SearXNG:     http://localhost:%SEARXNG_PORT%
echo.
echo Logs also saved to: %LOGS_PATH%
echo.
echo Model toggle in UI header next to Memory indicator
echo.
pause
goto menu

:launch_basic
cls
echo ===================================================
echo LAUNCHING BASIC STACK - VISIBLE OUTPUT (Port %FRONTEND_PORT%)
echo ===================================================
echo.

:: Kill existing processes
taskkill /F /IM python.exe >nul 2>&1
taskkill /F /IM node.exe >nul 2>&1
timeout /t 2 /nobreak >nul

:: ChromaDB - VISIBLE
echo [1/3] Starting ChromaDB Memory (visible)...
if not exist "%PROJECT_PATH%\chroma_data" mkdir "%PROJECT_PATH%\chroma_data"
start "ChromaDB" cmd /k "cd /d "%PROJECT_PATH%" && echo [CHROMADB] Running on port %CHROMA_PORT% && echo. && chroma run --path ./chroma_data --port %CHROMA_PORT%"
timeout /t 3 /nobreak >nul

:: FastAPI - VISIBLE
echo [2/3] Starting FastAPI Backend (visible)...
start "FastAPI" cmd /k "cd /d "%PROJECT_PATH%" && echo [FASTAPI] Starting on port %API_PORT% && echo. && python backend\kernel.py"
timeout /t 3 /nobreak >nul

:: Next.js - VISIBLE on selected port
echo [3/3] Starting Next.js Frontend on port %FRONTEND_PORT% (visible)...
start "Next.js" cmd /k "cd /d "%PROJECT_PATH%" && echo [NEXT.JS] Starting on port %FRONTEND_PORT% && echo. && npm run dev -- -p %FRONTEND_PORT%"

echo.
echo BASIC STACK LAUNCHED on port %FRONTEND_PORT% - Check the windows!
echo Frontend: http://localhost:%FRONTEND_PORT%
pause
goto menu

:launch_nextjs
cls
echo Starting Next.js Frontend on port %FRONTEND_PORT%...
if not exist "%PROJECT_PATH%\package.json" (
    echo ERROR: package.json not found
    pause
    goto menu
)
start "Next.js" cmd /k "cd /d "%PROJECT_PATH%" && echo [NEXT.JS] Starting on port %FRONTEND_PORT% && echo. && npm run dev -- -p %FRONTEND_PORT%"
echo Next.js window opened on port %FRONTEND_PORT% - Check it for output
echo Frontend: http://localhost:%FRONTEND_PORT%
pause
goto menu

:launch_chroma
cls
echo Starting ChromaDB Memory Server...
if not exist "%PROJECT_PATH%\chroma_data" mkdir "%PROJECT_PATH%\chroma_data"
start "ChromaDB" cmd /k "cd /d "%PROJECT_PATH%" && echo [CHROMADB] Running on port %CHROMA_PORT% && echo. && chroma run --path ./chroma_data --port %CHROMA_PORT%"
echo ChromaDB window opened - Check it for output
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
start "FastAPI" cmd /k "cd /d "%PROJECT_PATH%" && echo [FASTAPI] Starting on port %API_PORT% && echo. && python backend\kernel.py"
echo FastAPI window opened - Check it for output
pause
goto menu

:view_logs
cls
echo ===================================================
echo   LIVE LOG FILES
echo ===================================================
echo.
if exist "%LOGS_PATH%" (
    dir /b "%LOGS_PATH%\*.log" 2>nul
    if errorlevel 1 echo No log files found yet
) else (
    echo Logs directory not found
)
echo.
echo To view a log file, type: type %LOGS_PATH%\filename.log
echo.
pause
goto menu

:launch_searxng
cls
echo Starting SearXNG Web Search...
docker start searxng >nul 2>&1
if %errorlevel%==0 (
    echo [OK] SearXNG running at http://localhost:%SEARXNG_PORT%
) else (
    echo Creating new SearXNG container...
    docker run -d --name searxng -p %SEARXNG_PORT%:8080 searxng/searxng:latest
    if %errorlevel%==0 (
        echo [OK] SearXNG created and running
    ) else (
        echo [ERROR] Failed - Is Docker Desktop running?
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
    
    echo Starting executive_mcp.py (visible)...
    start "MCP-Executive" wsl -d %WSL_DISTRO% bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && echo '[MCP-EXEC] Starting...' && python3 mcp_servers/executive_mcp.py"
    
    echo Starting system_mcp.py (visible)...
    start "MCP-System" wsl -d %WSL_DISTRO% bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && echo '[MCP-SYS] Starting...' && python3 mcp_servers/system_mcp.py"
    
    echo Starting process_mcp.py (visible)...
    start "MCP-Process" wsl -d %WSL_DISTRO% bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && echo '[MCP-PROC] Starting...' && python3 mcp_servers/process_mcp.py"
    
    echo Starting research_mcp.py (visible)...
    start "MCP-Research" wsl -d %WSL_DISTRO% bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && echo '[MCP-RESEARCH] Starting...' && python3 mcp_servers/research_mcp.py"
    
    echo Starting rag_pipeline.py (visible)...
    start "MCP-RAG" wsl -d %WSL_DISTRO% bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && echo '[MCP-RAG] Starting...' && python3 mcp_servers/rag_pipeline.py"
    
    echo [OK] All MCP servers started - Check their windows
) else (
    echo [ERROR] MCP servers directory not found
)
pause
goto menu

:status
cls
echo ===================================================
echo   SERVICE STATUS
echo ===================================================
echo.

:: Check ports (check both 3000 and 3001 for Next.js)
netstat -ano | findstr ":3000" | findstr "LISTENING" >nul
if %errorlevel%==0 (
    echo [OK] Next.js:   RUNNING on port 3000
) else (
    netstat -ano | findstr ":3001" | findstr "LISTENING" >nul
    if %errorlevel%==0 (
        echo [OK] Next.js:   RUNNING on port 3001
    ) else (
        echo [OFF] Next.js:   OFFLINE
    )
)

netstat -ano | findstr ":%API_PORT%" | findstr "LISTENING" >nul && echo [OK] FastAPI:   RUNNING on port %API_PORT% || echo [OFF] FastAPI:   OFFLINE
netstat -ano | findstr ":%CHROMA_PORT%" | findstr "LISTENING" >nul && echo [OK] ChromaDB:  RUNNING on port %CHROMA_PORT% || echo [OFF] ChromaDB:  OFFLINE
netstat -ano | findstr ":11434" | findstr "LISTENING" >nul && echo [OK] Ollama:    RUNNING || echo [WARN] Ollama:    OFFLINE

:: Check Docker
docker ps 2>nul | findstr "searxng" >nul && echo [OK] SearXNG:   RUNNING || echo [WARN] SearXNG:   OFFLINE

:: Check if windows are open
tasklist | findstr "python.exe" >nul && echo [OK] Python:    RUNNING || echo [WARN] Python:    STOPPED
tasklist | findstr "node.exe" >nul && echo [OK] Node:      RUNNING || echo [WARN] Node:      STOPPED

echo.
echo ACTIVE WINDOWS SHOULD INCLUDE:
echo - ChromaDB, FastAPI, Next.js, MCP-* (if launched)
echo.
pause
goto menu

:list_models
cls
echo ===================================================
echo   AVAILABLE OLLAMA MODELS
echo ===================================================
echo.
ollama list
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
echo [OK] All services stopped
pause
goto menu