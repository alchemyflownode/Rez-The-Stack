@echo off
title REZ HIVE - QUICK FIX 🏛️
color 0A

echo ========================================
echo    REZ HIVE - QUICK FIX UTILITY
echo ========================================
echo.

:: 1. Fix Ollama Model
echo [1/4] Checking Ollama models...
ollama list | findstr "llama3.2" >nul
if %errorlevel%==0 (
    echo   ✅ llama3.2 model found
) else (
    echo   ⚠️ llama3.2 model missing - pulling now...
    ollama pull llama3.2
)

:: 2. Fix SearXNG
echo.
echo [2/4] Checking SearXNG...
docker ps | findstr "searxng" >nul
if %errorlevel%==0 (
    echo   ✅ SearXNG is running
) else (
    echo   ⚠️ SearXNG not running - starting...
    docker start searxng >nul 2>&1
    if %errorlevel%==0 (
        echo   ✅ SearXNG started
    ) else (
        echo   Creating new SearXNG container...
        docker run -d --name searxng -p 8080:8080 searxng/searxng:latest
    )
)

:: 3. Check ChromaDB
echo.
echo [3/4] Checking ChromaDB...
netstat -ano | findstr ":8000" | findstr "LISTENING" >nul
if %errorlevel%==0 (
    echo   ✅ ChromaDB is running
) else (
    echo   ⚠️ ChromaDB not running - start with option 2 in launcher
)

:: 4. Test API Connection
echo.
echo [4/4] Testing API connection...
curl -s http://localhost:8001/api/status >nul
if %errorlevel%==0 (
    echo   ✅ FastAPI is responding
) else (
    echo   ⚠️ FastAPI not responding - start with option 3 in launcher
)

echo.
echo ========================================
echo    FIXES APPLIED
echo ========================================
echo.
echo 📍 Next steps:
echo   1. Run your launcher (option 1) to start all services
echo   2. Open http://localhost:3000
echo   3. Test: "what can you help me with?"
echo.
pause