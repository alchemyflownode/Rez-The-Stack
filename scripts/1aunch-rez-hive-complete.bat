@echo off
title REZ HIVE SOVEREIGN LAUNCHER v5.2 - WITH OLLAMA CHECK
color 0A

set "PROJECT_PATH=D:\okiru-os\The Reztack OS"
set "VENV_PYTHON=%PROJECT_PATH%\backend\venv\Scripts\python.exe"
set "VENV_CHROMA=%PROJECT_PATH%\backend\venv\Scripts\chroma.exe"
set "OLLAMA_PATH=C:\Users\Zphoenix\AppData\Local\Programs\Ollama"
set "CHROMA_PORT=8000"
set "API_PORT=8001"
set "FRONTEND_PORT=3001"

:: Kill existing processes
echo [1/5] Cleaning up existing processes...
taskkill /F /IM python.exe >nul 2>&1
taskkill /F /IM node.exe >nul 2>&1
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :%API_PORT% ^| findstr LISTENING') do (
    taskkill /F /PID %%a >nul 2>&1
)
timeout /t 2 /nobreak >nul
echo   [OK] Cleanup complete
echo.

:: Check/Start Ollama
echo [2/5] Checking Ollama service...
curl -s http://localhost:11434/api/version >nul 2>&1
if %errorlevel%==0 (
    echo   [OK] Ollama is running
) else (
    echo   [WARN] Ollama not running - starting...
    start "" "%OLLAMA_PATH%\ollama app.exe"
    timeout /t 5 /nobreak >nul
    curl -s http://localhost:11434/api/version >nul 2>&1
    if %errorlevel%==0 (
        echo   [OK] Ollama started successfully
    ) else (
        echo   [ERROR] Failed to start Ollama
    )
)
echo.

:: 1. ChromaDB
echo [3/5] Starting ChromaDB Memory...
if not exist "%PROJECT_PATH%\chroma_data" mkdir "%PROJECT_PATH%\chroma_data"
start "ChromaDB" cmd /k "cd /d "%PROJECT_PATH%" && echo [CHROMADB] Running on port %CHROMA_PORT% && echo. && "%VENV_CHROMA%" run --path ./chroma_data --port %CHROMA_PORT%"
timeout /t 3 /nobreak >nul
echo   [OK] ChromaDB started
echo.

:: 2. Kernel (USING VENV PYTHON!)
echo [4/5] Starting REZ HIVE Kernel (VENV)...
start "FastAPI" cmd /k "cd /d "%PROJECT_PATH%" && set REZ_KERNEL_PORT=%API_PORT% && echo [FASTAPI] Starting on port %API_PORT% && echo. && "%VENV_PYTHON%" backend\kernel.py"
timeout /t 3 /nobreak >nul
echo   [OK] Kernel started
echo.

:: 3. Next.js
echo [5/5] Starting Next.js Frontend...
if exist "%PROJECT_PATH%\package.json" (
    start "Next.js" cmd /k "cd /d "%PROJECT_PATH%" && echo [NEXT.JS] Starting on port %FRONTEND_PORT% && echo. && npm run dev -- -p %FRONTEND_PORT%"
    echo   [OK] Next.js started
) else (
    echo   [WARN] package.json not found
)
echo.

echo ===================================================
echo ✅ EVERYTHING LAUNCHED!
echo ===================================================
echo.
echo Services:
echo   - Ollama:  http://localhost:11434
echo   - ChromaDB: http://localhost:%CHROMA_PORT%
echo   - Kernel:   http://localhost:%API_PORT%
echo   - Frontend: http://localhost:%FRONTEND_PORT%
echo.
pause