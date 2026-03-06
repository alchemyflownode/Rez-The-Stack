@echo off
title REZ HIVE CONTROL CONSOLE
color 0A

:menu
cls
echo.
echo  ========================================
echo    REZ HIVE SOVEREIGN CONTROL CONSOLE
echo  ========================================
echo.
echo    1. START STACK    (Ollama + Server)
echo    2. STOP SERVER    (Kill Port 3001)
echo    3. RESTART STACK  (Full Reset)
echo    4. CLEAN CACHE    (Delete .next)
echo    5. STATUS CHECK   (Ports + Ollama)
echo    6. PULL MODEL     (Download llama3.2:3b)
echo    7. EXIT
echo.
echo ========================================
set /p choice="Select Option [1-7]: "

if "%choice%"=="1" goto start
if "%choice%"=="2" goto stop
if "%choice%"=="3" goto restart
if "%choice%"=="4" goto clean
if "%choice%"=="5" goto status
if "%choice%"=="6" goto pull
if "%choice%"=="7" exit

:start
echo.
echo [START] Initializing Sovereign Stack...
echo.

:: 1. CHECK OLLAMA (The Brain)
echo [1/5] Verifying Ollama Service...
curl -s http://localhost:11434/api/tags >nul 2>&1
if %errorlevel% neq 0 (
    echo      Ollama Offline. Waking service...
    start "Ollama Service" /min ollama serve
    timeout /t 5 >nul
    
    curl -s http://localhost:11434/api/tags >nul 2>&1
    if %errorlevel% neq 0 (
        echo      ERROR: Ollama failed to start.
        echo      Ensure Ollama is installed and in PATH.
        pause
        goto menu
    )
)
echo      Ollama Online.

:: 2. Kill Port
echo [2/5] Clearing Port 3001...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3001') do (
    taskkill /PID %%a /F >nul 2>&1
)

:: 3. Clean Cache
echo [3/5] Purging Cache (.next)...
if exist .next rmdir /s /q .next

:: 4. Set Environment
echo [4/5] Configuring Environment...
set NEXT_TURBOPACK=0

:: 5. Start Server
echo [5/5] Spawning Server Process...
start "REZ HIVE SERVER" cmd /k "bun run next dev -p 3001 --webpack"
echo.
echo ========================================
echo   SERVER ONLINE
echo   Interface: http://localhost:3001
echo   Ollama API: http://localhost:11434
echo ========================================
echo.
pause
goto menu

:stop
echo.
echo [STOP] Terminating Server...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3001') do (
    taskkill /PID %%a /F >nul 2>&1
)
echo   Server Stopped.
echo.
pause
goto menu

:restart
echo.
echo [RESTART] Cycling Stack...
goto stop
goto start

:clean
echo.
echo [CLEAN] Deep Cleaning...
if exist .next rmdir /s /q .next
if exist node_modules\.cache rmdir /s /q node_modules\.cache
echo   Cache cleared.
echo.
pause
goto menu

:status
echo.
echo [STATUS] System Check...
echo.
echo  --- Port 3001 (Interface) ---
netstat -ano | findstr :3001
if %errorlevel%==0 (
    echo      STATUS: ONLINE
) else (
    echo      STATUS: OFFLINE
)
echo.
echo  --- Ollama (Brain) ---
curl -s http://localhost:11434/api/tags >nul 2>&1
if %errorlevel%==0 (
    echo      STATUS: ONLINE
    ollama list
) else (
    echo      STATUS: OFFLINE
)
echo.
pause
goto menu

:pull
echo.
echo [PULL] Downloading llama3.2:3b...
ollama pull llama3.2:3b
echo.
pause
goto menu