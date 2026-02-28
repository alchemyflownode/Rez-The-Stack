@echo off
title REZ HIVE - SOVEREIGN BOOT SEQUENCE

echo ========================================
echo    REZ HIVE - SOVEREIGN BOOT SEQUENCE
echo ========================================
echo.

echo [1/4] Terminating old instances...
taskkill /F /IM node.exe >nul 2>&1
taskkill /F /IM ollama.exe >nul 2>&1
timeout /t 2 >nul

echo [2/4] Waking the Brain (Ollama)...
start "" "C:\Users\Zphoenix\AppData\Local\Programs\Ollama\ollama app.exe"
timeout /t 10 >nul

echo [3/4] Loading Cognitive Models...
ollama run llama3.2:3b "" >nul 2>&1
ollama run llava:7b "" >nul 2>&1
echo      - Llama 3.2 (Brain) :: READY
echo      - Llava (Eyes)     :: READY

echo [4/4] Starting the Queen (Kernel)...
cd /d "G:\okiru\app builder\Cognitive Kernel"
start "" cmd /k "$env:NEXT_TURBOPACK=0; bun run next dev -p 3001 --webpack"

echo.
echo ========================================
echo    HIVE IS ONLINE.
echo    Interface: http://localhost:3001
echo ========================================
pause
