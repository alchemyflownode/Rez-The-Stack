@echo off
title REZ HIVE CONTROL CONSOLE
color 0A

:: Set the correct project path (CHANGE THIS IF NEEDED)
set "PROJECT_PATH=D:\okiru-os\The Reztack OS"

:menu
cls
echo.
echo  ========================================
echo    REZ HIVE SOVEREIGN CONTROL CONSOLE
echo  ========================================
echo.
echo    1. START STACK    (Ollama + Server)
echo    2. STOP SERVER
echo    3. RESTART STACK
echo    4. CLEAN CACHE
echo    5. STATUS CHECK
echo    6. PULL MODEL (llama3.2:3b)
echo    7. EXIT
echo.
echo ========================================
set /p "choice=Select Option [1-7]: "

if "%choice%"=="1" goto start
if "%choice%"=="2" goto stop
if "%choice%"=="3" goto restart
if "%choice%"=="4" goto clean
if "%choice%"=="5" goto status
if "%choice%"=="6" goto pull
if "%choice%"=="7" exit
goto menu

:start
cls
echo.
echo [START] Awakening Sovereign Stack...
echo.
echo [1/5] Verifying Ollama (The Brain)...

:: Check if Ollama is running
curl -s http://localhost:11434/api/tags >nul 2>&1
if %errorlevel% neq 0 (
    echo      Ollama Offline. Waking...
    start /min "Ollama Service" "C:\Users\Zphoenix\AppData\Local\Programs\Ollama\ollama.exe" serve
    timeout /t 5 /nobreak >nul
    echo      Ollama Service Started.
) else (
    echo      Ollama Online.
)

echo [2/5] Clearing Ports 3000/3001...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3000') do (
    if not "%%a"=="" taskkill /PID %%a /F >nul 2>&1
)
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3001') do (
    if not "%%a"=="" taskkill /PID %%a /F >nul 2>&1
)

echo [3/5] Purging Cache...
cd /d "%PROJECT_PATH%" 2>nul || (
    echo      ERROR: Project path not found!
    echo      Path: %PROJECT_PATH%
    pause
    goto menu
)

if exist ".next" (
    rmdir /s /q .next
    echo      Cache cleared.
) else (
    echo      No cache found.
)

echo [4/5] Setting Environment...
set NEXT_TURBOPACK=0

echo [5/5] Spawning Server...

:: CHECK WHICH PACKAGE MANAGER TO USE
where bun >nul 2>&1
if %errorlevel%==0 (
    echo      Using Bun...
    start "REZ HIVE SERVER" cmd /k "bun run dev"
) else (
    echo      Using NPM...
    start "REZ HIVE SERVER" cmd /k "npm run dev"
)

:: Wait for server to start
echo      Waiting for server to initialize...
timeout /t 8 /nobreak >nul

:: OPEN BROWSER AUTOMATICALLY
echo.
echo ========================================
echo   ✅ SERVER ONLINE
echo   📍 Opening dashboard in browser...
echo ========================================
timeout /t 2 /nobreak >nul
start http://localhost:3000

echo.
echo Press any key to return to menu...
pause >nul
goto menu

:stop
cls
echo.
echo [STOP] Shutting down services...
echo.

:: Kill Next.js server processes
echo Killing Next.js processes...
for /f "tokens=2" %%a in ('tasklist ^| findstr /i "node.exe"') do (
    taskkill /PID %%a /F >nul 2>&1
)

:: Kill specific ports
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3000') do (
    if not "%%a"=="" taskkill /PID %%a /F >nul 2>&1
)
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3001') do (
    if not "%%a"=="" taskkill /PID %%a /F >nul 2>&1
)

echo   ✅ All services stopped.
echo.
pause
goto menu

:restart
cls
echo.
echo [RESTART] Recycling Sovereign Stack...
echo.
call :stop
timeout /t 3 /nobreak >nul
goto start

:clean
cls
echo.
echo [CLEAN] Purging cache...
echo.
cd /d "%PROJECT_PATH%" 2>nul || (
    echo   ❌ ERROR: Project path not found!
    pause
    goto menu
)

if exist ".next" (
    rmdir /s /q .next
    echo   ✅ Cache purged.
) else (
    echo   ℹ️  No cache found.
)

if exist "node_modules\.cache" (
    rmdir /s /q "node_modules\.cache"
    echo   ✅ Module cache purged.
)

echo.
pause
goto menu

:status
cls
echo.
echo ============== STATUS CHECK ==============
echo.

echo --- Port 3000 (Next.js) ---
netstat -ano | findstr :3000
echo.

echo --- Port 3001 (Alternate) ---
netstat -ano | findstr :3001
echo.

echo --- Node Processes ---
tasklist | findstr /i "node.exe"
echo.

echo --- Ollama Status ---
curl -s http://localhost:11434/api/tags >nul 2>&1
if %errorlevel%==0 (
    echo Ollama: ✅ ONLINE
    echo.
    echo --- Available Models ---
    curl -s http://localhost:11434/api/tags | findstr /i "name"
) else (
    echo Ollama: ❌ OFFLINE
)
echo.
echo ========================================
echo.
pause
goto menu

:pull
cls
echo.
echo [PULL] Downloading llama3.2:3b...
echo.
ollama pull llama3.2:3b
echo.
echo ✅ Model pull complete!
pause
goto menu

:error
echo.
echo ❌ An error occurred. Please check:
echo    - Project path: %PROJECT_PATH%
echo    - Node.js installed
echo    - Ollama installed
pause
goto menu