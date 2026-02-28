@echo off
echo ========================================
echo Starting Rez Hive + ComfyUI Canvas Stack
echo ========================================
echo.

:: Start ComfyUI in its own window
echo [1/2] Starting ComfyUI...
start "ComfyUI" cmd /c "cd /d D:\ComfyUI_windows_portable_nvidia\ComfyUI_windows_portable && python_embeded\python.exe ComfyUI\main.py"

:: Wait for ComfyUI to initialize
echo Waiting 15 seconds for ComfyUI...
timeout /t 15 /nobreak > nul

:: Start Rez Hive
echo [2/2] Starting Rez Hive...
cd /d "%~dp0"
echo Server will be at http://localhost:3001
echo.
$env:NEXT_TURBOPACK=0; bun run next dev -p 3001 --webpack
