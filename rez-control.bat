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
echo    2. STOP SERVER
echo    3. RESTART STACK
echo    4. CLEAN CACHE
echo    5. STATUS CHECK
echo    6. PULL MODEL (llama3.2:3b)
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
echo [START] Awakening Sovereign Stack...
echo.
echo [1/5] Verifying Ollama (The Brain)...
curl -s http://localhost:11434/api/tags >nul 2>&1
if %errorlevel% neq 0 (
    echo      Ollama Offline. Waking...
    start "Ollama Service" /min ollama serve
    timeout /t 5 >nul
)
echo      Ollama Online.

echo [2/5] Clearing Port 3001...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3001') do taskkill /PID %%a /F >nul 2>&1

echo [3/5] Purging Cache...
if exist .next rmdir /s /q .next

echo [4/5] Environment...
set NEXT_TURBOPACK=0

echo [5/5] Spawning Server...
start "REZ HIVE SERVER" cmd /k "bun run next dev -p 3001 --webpack"

:: Wait for server to start
timeout /t 5 >nul

:: OPEN BROWSER AUTOMATICALLY to your dashboard
echo.
echo ========================================
echo   SERVER ONLINE
echo   Opening dashboard in browser...
echo ========================================
start http://localhost:3001

pause
goto menu

:stop
echo Stopping...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3001') do taskkill /PID %%a /F >nul 2>&1
echo   Stopped.
pause
goto menu

:restart
echo Restarting...
goto stop
timeout /t 2 >nul
goto start

:clean
echo Cleaning...
if exist .next rmdir /s /q .next
echo   Done.
pause
goto menu

:status
echo.
echo  --- Port 3001 ---
netstat -ano | findstr :3001
echo.
echo  --- Ollama ---
curl -s http://localhost:11434/api/tags >nul 2>&1
if %errorlevel%==0 (echo ONLINE) else (echo OFFLINE)
pause
goto menu

:pull
ollama pull llama3.2:3b
pause
goto menu