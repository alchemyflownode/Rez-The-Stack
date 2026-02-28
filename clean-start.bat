@echo off
title REZ HIVE CLEAN START
color 0A

echo ========================================
echo  ?? REZ HIVE - CLEAN START
echo ========================================
echo.

echo [1/4] Stopping all Node processes...
taskkill /F /IM node.exe >nul 2>&1
taskkill /F /IM nodejs.exe >nul 2>&1
timeout /t 2 >nul

echo [2/4] Removing .next cache...
if exist .next (
    takeown /F .next /R /D Y >nul 2>&1
    icacls .next /grant "Everyone:F" /T >nul 2>&1
    rmdir /s /q .next >nul 2>&1
    if exist .next (
        echo  ??  Could not remove .next - will continue anyway
    ) else (
        echo  ? .next removed
    )
) else (
    echo  ? No cache found
)

echo [3/4] Starting Ollama...
start /min "Ollama" ollama serve
timeout /t 3 >nul

echo [4/4] Starting Server...
start "REZ HIVE SERVER" cmd /k "bun run next dev -p 3001 --webpack"

echo.
echo ========================================
echo  ? SERVER STARTING
echo  Interface: http://localhost:3001
echo ========================================
