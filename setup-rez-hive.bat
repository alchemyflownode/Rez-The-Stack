@echo off
title REZ HIVE - ONE-TIME SETUP 🏛️
color 0A

echo ========================================
echo    SETTING UP REZ HIVE SOVEREIGN STACK
echo ========================================
echo.

:: Install Python packages (Windows)
echo [1/5] Installing Windows Python packages...
pip install fastapi uvicorn chromadb ollama sentence-transformers psutil requests

:: Install WSL Python packages
echo [2/5] Installing WSL Python packages...
wsl -d Ubuntu -e bash -c "sudo apt update && sudo apt install -y python3-pip && pip3 install chromadb sentence-transformers psutil requests"

:: Pull SearXNG Docker image
echo [3/5] Pulling SearXNG Docker image...
docker pull searxng/searxng:latest

:: Create MCP directory
echo [4/5] Creating MCP directory...
if not exist "mcp_servers" mkdir mcp_servers

:: Create .env file
echo [5/5] Creating .env file...
echo OLLAMA_BASE_URL=http://localhost:11434 > .env
echo OLLAMA_MODEL=llama3.2 >> .env
echo API_URL=http://localhost:8001 >> .env
echo SEARXNG_URL=http://localhost:8080 >> .env

echo.
echo ========================================
echo    ✅ SETUP COMPLETE!
echo ========================================
echo.
echo Now run: start-rez-hive.bat
echo.
pause