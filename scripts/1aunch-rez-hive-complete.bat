@echo off
title REZ HIVE SOVEREIGN LAUNCHER v5.3 - SOFT MODE
color 0A

set "PROJECT_PATH=D:\okiru-os\The Reztack OS"
set "VENV_PYTHON=%PROJECT_PATH%\backend\venv\Scripts\python.exe"
set "VENV_CHROMA=%PROJECT_PATH%\backend\venv\Scripts\chroma.exe"
set "OLLAMA_PATH=C:\Users\Zphoenix\AppData\Local\Programs\Ollama"
set "CHROMA_PORT=8000"
set "API_PORT=8001"
set "FRONTEND_PORT=3001"

:: Create logs directory
if not exist "%PROJECT_PATH%\logs" mkdir "%PROJECT_PATH%\logs"
set "LOG_FILE=%PROJECT_PATH%\logs\launch_%DATE:~-4,4%%DATE:~-10,2%%DATE:~-7,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%.log"
set "LOG_FILE=%LOG_FILE: =0%"

echo =================================================== > "%LOG_FILE%"
echo REZ HIVE LAUNCH LOG - %DATE% %TIME% >> "%LOG_FILE%"
echo =================================================== >> "%LOG_FILE%"

:: Function to check if port is free (no killing)
:check_port
set "port=%~1"
netstat -ano | findstr :%port% >nul
if %errorlevel%==0 (
    echo   ⚠️ Port %port% is in use - may cause conflicts
    echo   [WARN] Port %port% in use >> "%LOG_FILE%"
) else (
    echo   ✅ Port %port% is free
)
exit /b 0

echo.
echo [1/5] Checking system...
echo [1/5] System check >> "%LOG_FILE%"

:: Check Python
if exist "%VENV_PYTHON%" (
    echo   ✅ Python: Found
    echo   [OK] Python found >> "%LOG_FILE%"
) else (
    echo   ❌ Python: Not found at %VENV_PYTHON%
    echo   [ERROR] Python missing >> "%LOG_FILE%"
    pause
    exit /b 1
)

:: Check ports (don't kill, just warn)
echo.
echo Checking ports...
call :check_port %API_PORT%
call :check_port %CHROMA_PORT%
call :check_port %FRONTEND_PORT%

echo.

:: Check/Start Ollama (NO KILLING)
echo [2/5] Checking Ollama service...
echo [2/5] Ollama check >> "%LOG_FILE%"
curl -s http://localhost:11434/api/version >nul 2>&1
if %errorlevel%==0 (
    echo   ✅ Ollama is running
    echo   [OK] Ollama running >> "%LOG_FILE%"
    
    :: Show available models
    echo   Models available:
    curl -s http://localhost:11434/api/tags | findstr /i "name" 2>nul
) else (
    echo   ⚠️ Ollama not running - you can start manually:
    echo   "%OLLAMA_PATH%\ollama.exe" serve
    echo   [WARN] Ollama not running >> "%LOG_FILE%"
)
echo.

:: 1. ChromaDB (check first, then start if needed)
echo [3/5] Checking ChromaDB...
echo [3/5] ChromaDB check >> "%LOG_FILE%"
curl -s http://localhost:%CHROMA_PORT%/api/v1/heartbeat >nul 2>&1
if %errorlevel%==0 (
    echo   ✅ ChromaDB already running on port %CHROMA_PORT%
    echo   [OK] ChromaDB already running >> "%LOG_FILE%"
) else (
    echo   🚀 Starting ChromaDB...
    if not exist "%PROJECT_PATH%\chroma_data" mkdir "%PROJECT_PATH%\chroma_data"
    start "ChromaDB" cmd /c "cd /d "%PROJECT_PATH%" && "%VENV_CHROMA%" run --path ./chroma_data --port %CHROMA_PORT% > "%PROJECT_PATH%\logs\chroma.log" 2>&1"
    timeout /t 3 /nobreak >nul
    echo   ✅ ChromaDB started
    echo   [OK] ChromaDB started >> "%LOG_FILE%"
)
echo.

:: 2. Kernel (check first)
echo [4/5] Checking Kernel...
echo [4/5] Kernel check >> "%LOG_FILE%"
curl -s http://localhost:%API_PORT%/health >nul 2>&1
if %errorlevel%==0 (
    echo   ✅ Kernel already running on port %API_PORT%
    echo   [OK] Kernel already running >> "%LOG_FILE%"
) else (
    echo   🚀 Starting REZ HIVE Kernel...
    start "FastAPI Kernel" cmd /c "cd /d "%PROJECT_PATH%" && set REZ_KERNEL_PORT=%API_PORT% && "%VENV_PYTHON%" backend\kernel.py > "%PROJECT_PATH%\logs\kernel.log" 2>&1"
    timeout /t 3 /nobreak >nul
    echo   ✅ Kernel started
    echo   [OK] Kernel started >> "%LOG_FILE%"
)
echo.

:: 3. Next.js (check first)
echo [5/5] Checking Frontend...
echo [5/5] Frontend check >> "%LOG_FILE%"
curl -s http://localhost:%FRONTEND_PORT% >nul 2>&1
if %errorlevel%==0 (
    echo   ✅ Frontend already running on port %FRONTEND_PORT%
    echo   [OK] Frontend already running >> "%LOG_FILE%"
) else (
    if exist "%PROJECT_PATH%\package.json" (
        echo   🚀 Starting Next.js Frontend...
        start "Next.js Frontend" cmd /c "cd /d "%PROJECT_PATH%" && npm run dev -- -p %FRONTEND_PORT% > "%PROJECT_PATH%\logs\frontend.log" 2>&1"
        echo   ✅ Frontend started
        echo   [OK] Frontend started >> "%LOG_FILE%"
    ) else (
        echo   ⚠️ package.json not found
        echo   [WARN] package.json missing >> "%LOG_FILE%"
    )
)
echo.

:: Final Status
echo ===================================================
echo ✅ LAUNCH SEQUENCE COMPLETE
echo ===================================================
echo.
echo 📊 SERVICE STATUS:
curl -s http://localhost:%CHROMA_PORT%/api/v1/heartbeat >nul 2>&1 && echo   ✅ ChromaDB: RUNNING || echo   ⚠️ ChromaDB: STARTING
curl -s http://localhost:%API_PORT%/health >nul 2>&1 && echo   ✅ Kernel: RUNNING || echo   ⚠️ Kernel: STARTING
curl -s http://localhost:%FRONTEND_PORT% >nul 2>&1 && echo   ✅ Frontend: RUNNING || echo   ⚠️ Frontend: STARTING
curl -s http://localhost:11434/api/version >nul 2>&1 && echo   ✅ Ollama: RUNNING || echo   ⚠️ Ollama: NOT RUNNING

echo.
echo 🌐 ACCESS POINTS:
echo   - Frontend: http://localhost:%FRONTEND_PORT%
echo   - Kernel API: http://localhost:%API_PORT%/docs
echo   - ChromaDB: http://localhost:%CHROMA_PORT%
echo   - Ollama: http://localhost:11434
echo.
echo 📁 Logs: %PROJECT_PATH%\logs\
echo.
echo Press any key to open Rez Hive...
pause >nul

:: Open frontend
start http://localhost:%FRONTEND_PORT%

:: Show running processes
echo.
echo 🔄 Running Services:
tasklist | findstr /i "python node" 2>nul

echo.
echo 🚀 Rez Hive is ready!
pause