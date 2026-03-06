@echo off
echo Checking Ollama...
curl -s http://localhost:11434/api/version
if %errorlevel%==0 (
    echo.
    echo ✅ Ollama is running
) else (
    echo.
    echo ❌ Ollama is NOT running
    echo Starting Ollama...
    start "" "C:\Users\Zphoenix\AppData\Local\Programs\Ollama\ollama app.exe"
    timeout /t 3
)
pause