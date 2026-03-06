@echo off
title REZ HIVE SOVEREIGN LAUNCHER v5.0 - ZERO-DRIFT
color 0A

set "PROJECT_PATH=D:\okiru-os\The Reztack OS"
set "PYTHON_PATH=python"
set "CHROMA_PORT=8000"
set "API_PORT=8001"
set "FRONTEND_PORT=3001"
set "FRONTEND_PORT_ALT=3000"
set "SEARXNG_PORT=8080"
set "WSL_DISTRO=Ubuntu"
set "LOGS_PATH=%PROJECT_PATH%\logs"

:: Ollama paths
set "OLLAMA_PATH=C:\Users\Zphoenix\AppData\Local\Programs\Ollama"
set "OLLAMA_URL=http://localhost:11434"

:: Export kernel port for Python to read
set "REZ_KERNEL_PORT=%API_PORT%"

:: Create logs directory
if not exist "%LOGS_PATH%" mkdir "%LOGS_PATH%"

:menu
cls
echo ===================================================
echo     🏛️  REZ HIVE - SOVEREIGN LAUNCHER v5.0
echo          Zero-Drift Constitutional AI
echo ===================================================
echo.
echo  [1] LAUNCH EVERYTHING (Port 3001 - DEFAULT)
echo  [2] LAUNCH EVERYTHING (Port 3000 - Alternate)
echo  [3] LAUNCH BASIC STACK (Port 3001)
echo  [4] LAUNCH BASIC STACK (Port 3000)
echo  [5] LAUNCH CHROMADB ONLY
echo  [6] LAUNCH FASTAPI ONLY
echo  [7] LAUNCH NEXT.JS ONLY (Port 3001)
echo  [8] LAUNCH NEXT.JS ONLY (Port 3000)
echo  [9] LAUNCH SEARXNG ONLY
echo  [10] LAUNCH MCP SERVERS ONLY
echo  [11] LAUNCH STANDALONE HTML UI (No Next.js)
echo  [12] CHECK STATUS (ALL SERVICES)
echo  [13] STOP ALL SERVICES
echo  [14] LIST AVAILABLE MODELS
echo  [15] VIEW LIVE LOGS
echo  [16] KILL STUCK PROCESSES ON PORT 8001
echo  [17] INSTALL STANDALONE HTML UI
echo  [18] CHECK OLLAMA STATUS
echo  [19] START OLLAMA (if not running)
echo  [20] ZERO-DRIFT HEALTH AUDIT
echo  [0] EXIT
echo.
set /p choice=Select option [0-20]: 

if "%choice%"=="1" goto launch_everything_3001
if "%choice%"=="2" goto launch_everything_3000
if "%choice%"=="3" goto launch_basic_3001
if "%choice%"=="4" goto launch_basic_3000
if "%choice%"=="5" goto launch_chroma
if "%choice%"=="6" goto launch_fastapi
if "%choice%"=="7" goto launch_nextjs_3001
if "%choice%"=="8" goto launch_nextjs_3000
if "%choice%"=="9" goto launch_searxng
if "%choice%"=="10" goto launch_mcp
if "%choice%"=="11" goto launch_html_ui
if "%choice%"=="12" goto status
if "%choice%"=="13" goto kill
if "%choice%"=="14" goto list_models
if "%choice%"=="15" goto view_logs
if "%choice%"=="16" goto kill_port_8001
if "%choice%"=="17" goto install_html_ui
if "%choice%"=="18" goto check_ollama
if "%choice%"=="19" goto start_ollama
if "%choice%"=="20" goto zero_drift_audit
if "%choice%"=="0" exit /b 0
goto menu

:launch_everything_3001
set "FRONTEND_PORT=3001"
goto launch_everything

:launch_everything_3000
set "FRONTEND_PORT=3000"
goto launch_everything

:launch_basic_3001
set "FRONTEND_PORT=3001"
goto launch_basic

:launch_basic_3000
set "FRONTEND_PORT=3000"
goto launch_basic

:launch_nextjs_3001
set "FRONTEND_PORT=3001"
goto launch_nextjs

:launch_nextjs_3000
set "FRONTEND_PORT=3000"
goto launch_nextjs

:kill_port_8001
cls
echo ===================================================
echo   🔪 KILLING PROCESSES ON PORT 8001
echo ===================================================
echo.
echo Finding processes using port 8001...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8001 ^| findstr LISTENING') do (
    echo Killing PID: %%a
    taskkill /F /PID %%a >nul 2>&1
)
timeout /t 2 /nobreak >nul
echo.
echo [OK] Port 8001 should now be free
pause
goto menu

:check_ollama
cls
echo ===================================================
echo   🦊 OLLAMA STATUS
echo ===================================================
echo.
echo Checking if Ollama is running...
tasklist | findstr ollama.exe >nul
if %errorlevel%==0 (
    echo [OK] Ollama process is running
) else (
    echo [WARN] Ollama process not found
)

echo.
echo Testing API connection...
curl -s http://localhost:11434/api/version >nul 2>&1
if %errorlevel%==0 (
    echo [OK] Ollama API is responding
    echo.
    echo Current version:
    curl -s http://localhost:11434/api/version | findstr version
) else (
    echo [ERROR] Ollama API not responding
)

echo.
echo Installed models:
ollama list
echo.
pause
goto menu

:start_ollama
cls
echo ===================================================
echo   🚀 STARTING OLLAMA SERVICE
echo ===================================================
echo.
echo Starting Ollama from: %OLLAMA_PATH%
start "" "%OLLAMA_PATH%\ollama app.exe"
echo Waiting for service to initialize...
timeout /t 5 /nobreak >nul
echo.
echo Testing connection...
curl -s http://localhost:11434/api/version
echo.
echo [OK] Ollama started
pause
goto menu

:zero_drift_audit
cls
echo ===================================================
echo   🛡️  ZERO-DRIFT CONSTITUTIONAL AUDIT
echo ===================================================
echo.
echo Checking all sovereign services...

:: Check Kernel
netstat -ano | findstr ":%API_PORT%" | findstr "LISTENING" >nul
if %errorlevel%==0 (
    echo [✅] Kernel: RUNNING on port %API_PORT%
) else (
    echo [❌] Kernel: OFFLINE
)

:: Check ChromaDB
netstat -ano | findstr ":%CHROMA_PORT%" | findstr "LISTENING" >nul
if %errorlevel%==0 (
    echo [✅] ChromaDB: RUNNING on port %CHROMA_PORT%
) else (
    echo [❌] ChromaDB: OFFLINE
)

:: Check Next.js
netstat -ano | findstr ":%FRONTEND_PORT%" | findstr "LISTENING" >nul
if %errorlevel%==0 (
    echo [✅] Next.js: RUNNING on port %FRONTEND_PORT%
) else (
    netstat -ano | findstr ":3000" | findstr "LISTENING" >nul
    if %errorlevel%==0 (
        echo [✅] Next.js: RUNNING on port 3000 (alternate)
    ) else (
        echo [❌] Next.js: OFFLINE
    )
)

:: Check Ollama
curl -s http://localhost:11434/api/version >nul 2>&1
if %errorlevel%==0 (
    echo [✅] Ollama: RUNNING
) else (
    echo [❌] Ollama: OFFLINE
)

:: Check Database
if exist "%PROJECT_PATH%\backend\rez_hive.db" (
    echo [✅] Database: FOUND
) else (
    echo [⚠️] Database: Not found (will be created on first run)
)

:: Check Constitutional Files
if exist "%PROJECT_PATH%\backend\zero_drift_core.py" (
    echo [✅] Constitution: ACTIVE
) else (
    echo [⚠️] Constitution: Not loaded
)

:: Check PS1 Controller Integration
if exist "%PROJECT_PATH%\src\components\RezHiveController.tsx" (
    echo [✅] PS1 Controller: INSTALLED
) else (
    echo [⚠️] PS1 Controller: Not found
)

echo.
echo ===================================================
echo AUDIT COMPLETE
echo ===================================================
pause
goto menu

:install_html_ui
cls
echo ===================================================
echo   📦 INSTALLING STANDALONE HTML UI
echo ===================================================
echo.
echo This will create a beautiful REZ HIVE chat interface
echo that connects directly to your kernel.
echo.

:: Create public folder if it doesn't exist
if not exist "%PROJECT_PATH%\public" mkdir "%PROJECT_PATH%\public"

:: Download or create the HTML file
echo Creating REZ HIVE HTML UI...
(
echo ^<!DOCTYPE html^>
echo ^<html lang="en"^>
echo ^<head^>
echo ^<meta charset="UTF-8"^>
echo ^<meta name="viewport" content="width=device-width, initial-scale=1.0"^>
echo ^<title^>🏛️ REZ HIVE - Sovereign AI^</title^>
echo ^<script src="https://cdn.tailwindcss.com"^>^</script^>
echo ^<style^>
echo   body { background-color: #030405; font-family: 'JetBrains Mono', monospace; }
echo   .ai-bubble { background-color: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.05); }
echo   .user-bubble { background-color: rgba(6,182,212,0.1); border: 1px solid rgba(6,182,212,0.2); }
echo ^</style^>
echo ^</head^>
echo ^<body class="min-h-screen bg-[#030405] text-white p-4"^>
echo   ^<div class="max-w-3xl mx-auto"^>
echo     ^<h1 class="text-2xl font-bold text-cyan-400 mb-4"^>🏛️ REZ HIVE^</h1^>
echo     ^<div id="messages" class="space-y-4 mb-4 h-[70vh] overflow-y-auto"^>^</div^>
echo     ^<div class="flex gap-2"^>
echo       ^<input id="input" type="text" class="flex-1 bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-sm" placeholder="Message..."^>
echo       ^<button id="send" class="px-6 py-3 bg-cyan-500/10 border border-cyan-500/30 rounded-xl text-cyan-400"^>Send^</button^>
echo     ^</div^>
echo   ^</div^>
echo   ^<script^>
echo     const API_URL = "http://localhost:%API_PORT%/kernel/stream";
echo     const messages = document.getElementById("messages");
echo     const input = document.getElementById("input");
echo     const sendBtn = document.getElementById("send");
echo     
echo     function addMessage(content, role) {
echo       const div = document.createElement("div");
echo       div.className = `p-4 rounded-xl ${role === 'ai' ? 'ai-bubble' : 'user-bubble'} mb-3`;
echo       div.textContent = content;
echo       messages.appendChild(div);
echo       messages.scrollTop = messages.scrollHeight;
echo     }
echo     
echo     async function sendMessage() {
echo       const task = input.value.trim();
echo       if (!task) return;
echo       
echo       addMessage(task, "user");
echo       input.value = "";
echo       
echo       try {
echo         const response = await fetch(API_URL, {
echo           method: "POST",
echo           headers: { "Content-Type": "application/json" },
echo           body: JSON.stringify({ task, worker: "brain" })
echo         });
echo         
echo         const reader = response.body.getReader();
echo         const decoder = new TextDecoder();
echo         let accumulated = "";
echo         
echo         const aiDiv = document.createElement("div");
echo         aiDiv.className = "ai-bubble p-4 rounded-xl mb-3";
echo         messages.appendChild(aiDiv);
echo         
echo         while (true) {
echo           const { done, value } = await reader.read();
echo           if (done) break;
echo           
echo           const chunk = decoder.decode(value);
echo           const lines = chunk.split("\n\n");
echo           
echo           for (const line of lines) {
echo             if (line.startsWith("data: ")) {
echo               try {
echo                 const data = JSON.parse(line.slice(5));
echo                 if (data.content) {
echo                   accumulated += data.content;
echo                   aiDiv.textContent = accumulated;
echo                 }
echo               } catch (e) {}
echo             }
echo           }
echo           messages.scrollTop = messages.scrollHeight;
echo         }
echo       } catch (error) {
echo         addMessage(`⚠️ Error: ${error.message}`, "ai");
echo       }
echo     }
echo     
echo     sendBtn.addEventListener("click", sendMessage);
echo     input.addEventListener("keydown", (e) => {
echo       if (e.key === "Enter") sendMessage();
echo     });
echo     
echo     addMessage("Welcome to REZ HIVE! 👋\n\nI'm your sovereign AI coworker.", "ai");
echo   ^</script^>
echo ^</body^>
echo ^</html^>
) > "%PROJECT_PATH%\public\rez-hive.html"

echo.
echo [OK] HTML UI installed at: public\rez-hive.html
echo.
echo You can now access it at: http://localhost:%FRONTEND_PORT%/rez-hive.html
echo.
pause
goto menu

:launch_html_ui
cls
echo ===================================================
echo   🌐 LAUNCHING STANDALONE HTML UI
echo ===================================================
echo.
echo This starts ONLY the kernel and opens the HTML UI.
echo (No Next.js frontend needed)

:: Kill existing processes
taskkill /F /IM python.exe >nul 2>&1
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :%API_PORT% ^| findstr LISTENING') do (
    taskkill /F /PID %%a >nul 2>&1
)
timeout /t 2 /nobreak >nul

:: Start ChromaDB
echo Starting ChromaDB...
start "ChromaDB" cmd /k "cd /d "%PROJECT_PATH%" && echo [CHROMADB] Running on port %CHROMA_PORT% && echo. && chroma run --path ./chroma_data --port %CHROMA_PORT%"
timeout /t 3 /nobreak >nul

:: Start Kernel
echo Starting Kernel on port %API_PORT%...
start "FastAPI" cmd /k "cd /d "%PROJECT_PATH%" && set REZ_KERNEL_PORT=%API_PORT% && echo [FASTAPI] Starting on port %API_PORT% && echo. && python backend\kernel.py"
timeout /t 3 /nobreak >nul

:: Check if HTML UI exists
if not exist "%PROJECT_PATH%\public\rez-hive.html" (
    echo.
    echo [WARN] HTML UI not found. Run option 17 first.
    pause
    goto menu
)

echo.
echo ===================================================
echo ✅ STANDALONE UI READY!
echo ===================================================
echo.
echo Open this URL in your browser:
echo   http://localhost:%FRONTEND_PORT%/rez-hive.html
echo.
echo (Note: The file is served by your Next.js dev server)
echo.
pause
goto menu

:launch_everything
cls
echo ===================================================
echo 🚀 LAUNCHING EVERYTHING - VISIBLE OUTPUT (Port %FRONTEND_PORT%)
echo ===================================================
echo.

:: Kill existing processes MORE AGGRESSIVELY
echo [1/7] Cleaning up existing processes...

:: First try normal kill
taskkill /F /IM python.exe >nul 2>&1
taskkill /F /IM node.exe >nul 2>&1
wsl -d %WSL_DISTRO% -e bash -c "pkill -f mcp_servers" >nul 2>&1
docker stop searxng >nul 2>&1

:: Then specifically kill anything on API port
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :%API_PORT% ^| findstr LISTENING') do (
    taskkill /F /PID %%a >nul 2>&1
)

:: Clear Next.js cache to prevent stale builds
if exist "%PROJECT_PATH%\.next" (
    echo   Cleaning Next.js cache...
    rmdir /s /q "%PROJECT_PATH%\.next" >nul 2>&1
)

timeout /t 3 /nobreak >nul
echo   [OK] Cleanup complete
echo.

:: Check Ollama first (background service)
echo [2/7] Checking Ollama service...
curl -s http://localhost:11434/api/version >nul 2>&1
if %errorlevel%==0 (
    echo   [OK] Ollama is running
) else (
    echo   [WARN] Ollama not running - starting...
    start "" "%OLLAMA_PATH%\ollama app.exe"
    timeout /t 5 /nobreak >nul
)
echo.

:: 1. ChromaDB - VISIBLE output
echo [3/7] Starting ChromaDB Memory (visible window)...
if not exist "%PROJECT_PATH%\chroma_data" mkdir "%PROJECT_PATH%\chroma_data"
start "ChromaDB" cmd /k "cd /d "%PROJECT_PATH%" && echo [CHROMADB] Running on port %CHROMA_PORT% && echo. && chroma run --path ./chroma_data --port %CHROMA_PORT%"
timeout /t 3 /nobreak >nul
echo   [OK] ChromaDB window opened
echo.

:: 2. FastAPI - VISIBLE output (with REZ_KERNEL_PORT set)
echo [4/7] Starting FastAPI Backend on port %API_PORT% (visible window)...
if exist "%PROJECT_PATH%\backend\kernel.py" (
    start "FastAPI" cmd /k "cd /d "%PROJECT_PATH%" && set REZ_KERNEL_PORT=%API_PORT% && echo [FASTAPI] Starting on port %API_PORT% && echo. && python backend\kernel.py"
    echo   [OK] FastAPI window opened
) else (
    echo   [WARN] kernel.py not found - skipping
)
timeout /t 3 /nobreak >nul
echo.

:: 3. Next.js - VISIBLE output on selected port with clean cache
echo [5/7] Starting Next.js Frontend on port %FRONTEND_PORT% (visible window)...
if exist "%PROJECT_PATH%\package.json" (
    echo   Cleaning Next.js dev cache...
    if exist "%PROJECT_PATH%\.next\cache" rmdir /s /q "%PROJECT_PATH%\.next\cache" >nul 2>&1
    
    start "Next.js" cmd /k "cd /d "%PROJECT_PATH%" && echo [NEXT.JS] Starting on port %FRONTEND_PORT% && echo. && npm run dev -- -p %FRONTEND_PORT%"
    echo   [OK] Next.js window opened on port %FRONTEND_PORT%
) else (
    echo   [WARN] package.json not found - skipping
)
timeout /t 3 /nobreak >nul
echo.

:: 4. SearXNG
echo [6/7] Starting SearXNG Web Search...
docker start searxng >nul 2>&1
if %errorlevel%==0 (
    echo   [OK] SearXNG started (existing container)
) else (
    echo   Creating new SearXNG container...
    docker run -d --name searxng -p %SEARXNG_PORT%:8080 searxng/searxng:latest >nul 2>&1
    if %errorlevel%==0 (
        echo   [OK] SearXNG created and started
    ) else (
        echo   [WARN] SearXNG failed - Is Docker Desktop running?
    )
)
echo.

:: 5. MCP Servers
echo [7/7] Starting MCP Servers in WSL...
if exist "%PROJECT_PATH%\mcp_servers" (
    echo   Killing old MCP processes...
    wsl -d %WSL_DISTRO% -e bash -c "pkill -f mcp_servers" >nul 2>&1
    
    echo   Starting executive_mcp.py (visible)...
    start "MCP-Executive" wsl -d %WSL_DISTRO% bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && echo '[MCP-EXEC] Starting...' && python3 mcp_servers/executive_mcp.py"
    timeout /t 1 /nobreak >nul
    
    echo   Starting system_mcp.py (visible)...
    start "MCP-System" wsl -d %WSL_DISTRO% bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && echo '[MCP-SYS] Starting...' && python3 mcp_servers/system_mcp.py"
    timeout /t 1 /nobreak >nul
    
    echo   Starting process_mcp.py (visible)...
    start "MCP-Process" wsl -d %WSL_DISTRO% bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && echo '[MCP-PROC] Starting...' && python3 mcp_servers/process_mcp.py"
    timeout /t 1 /nobreak >nul
    
    echo   Starting research_mcp.py (visible)...
    start "MCP-Research" wsl -d %WSL_DISTRO% bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && echo '[MCP-RESEARCH] Starting...' && python3 mcp_servers/research_mcp.py"
    timeout /t 1 /nobreak >nul
    
    echo   Starting rag_pipeline.py (visible)...
    start "MCP-RAG" wsl -d %WSL_DISTRO% bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && echo '[MCP-RAG] Starting...' && python3 mcp_servers/rag_pipeline.py"
    
    echo   [OK] All MCP servers started - Check their windows
) else (
    echo   [WARN] MCP servers directory not found
)
echo.

echo ===================================================
echo ✅ EVERYTHING LAUNCHED on port %FRONTEND_PORT%!
echo ===================================================
echo.
echo LOOK FOR THESE WINDOWS:
echo - ChromaDB (port %CHROMA_PORT%)
echo - FastAPI (port %API_PORT%)
echo - Next.js (port %FRONTEND_PORT%)
echo - MCP-Executive, MCP-System, MCP-Process, etc.
echo.
echo Frontend:    http://localhost:%FRONTEND_PORT%
echo Backend API: http://localhost:%API_PORT%
echo SearXNG:     http://localhost:%SEARXNG_PORT%
echo HTML UI:     http://localhost:%FRONTEND_PORT%/rez-hive.html
echo.
echo Logs also saved to: %LOGS_PATH%
echo.
echo Model toggle in UI header next to Memory indicator
echo.
pause
goto menu

:launch_basic
cls
echo ===================================================
echo 🔧 LAUNCHING BASIC STACK - VISIBLE OUTPUT (Port %FRONTEND_PORT%)
echo ===================================================
echo.

:: Kill existing processes
taskkill /F /IM python.exe >nul 2>&1
taskkill /F /IM node.exe >nul 2>&1
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :%API_PORT% ^| findstr LISTENING') do (
    taskkill /F /PID %%a >nul 2>&1
)

:: Clear Next.js cache
if exist "%PROJECT_PATH%\.next" (
    echo Cleaning Next.js cache...
    rmdir /s /q "%PROJECT_PATH%\.next" >nul 2>&1
)
timeout /t 3 /nobreak >nul

:: Check Ollama
echo Checking Ollama...
curl -s http://localhost:11434/api/version >nul 2>&1
if %errorlevel%==0 (
    echo [OK] Ollama is running
) else (
    echo [WARN] Ollama not running - models may not load
)
echo.

:: ChromaDB - VISIBLE
echo [1/3] Starting ChromaDB Memory (visible)...
if not exist "%PROJECT_PATH%\chroma_data" mkdir "%PROJECT_PATH%\chroma_data"
start "ChromaDB" cmd /k "cd /d "%PROJECT_PATH%" && echo [CHROMADB] Running on port %CHROMA_PORT% && echo. && chroma run --path ./chroma_data --port %CHROMA_PORT%"
timeout /t 3 /nobreak >nul

:: FastAPI - VISIBLE (with REZ_KERNEL_PORT set)
echo [2/3] Starting FastAPI Backend on port %API_PORT% (visible)...
start "FastAPI" cmd /k "cd /d "%PROJECT_PATH%" && set REZ_KERNEL_PORT=%API_PORT% && echo [FASTAPI] Starting on port %API_PORT% && echo. && python backend\kernel.py"
timeout /t 3 /nobreak >nul

:: Next.js - VISIBLE on selected port
echo [3/3] Starting Next.js Frontend on port %FRONTEND_PORT% (visible)...
start "Next.js" cmd /k "cd /d "%PROJECT_PATH%" && echo [NEXT.JS] Starting on port %FRONTEND_PORT% && echo. && npm run dev -- -p %FRONTEND_PORT%"

echo.
echo BASIC STACK LAUNCHED on port %FRONTEND_PORT% - Check the windows!
echo Frontend: http://localhost:%FRONTEND_PORT%
echo HTML UI:  http://localhost:%FRONTEND_PORT%/rez-hive.html
pause
goto menu

:launch_nextjs
cls
echo Starting Next.js Frontend on port %FRONTEND_PORT%...
if not exist "%PROJECT_PATH%\package.json" (
    echo ERROR: package.json not found
    pause
    goto menu
)

:: Clear Next.js cache
if exist "%PROJECT_PATH%\.next" (
    echo Cleaning Next.js cache...
    rmdir /s /q "%PROJECT_PATH%\.next" >nul 2>&1
)

start "Next.js" cmd /k "cd /d "%PROJECT_PATH%" && echo [NEXT.JS] Starting on port %FRONTEND_PORT% && echo. && npm run dev -- -p %FRONTEND_PORT%"
echo Next.js window opened on port %FRONTEND_PORT% - Check it for output
echo Frontend: http://localhost:%FRONTEND_PORT%
echo HTML UI:  http://localhost:%FRONTEND_PORT%/rez-hive.html
pause
goto menu

:launch_chroma
cls
echo Starting ChromaDB Memory Server...
if not exist "%PROJECT_PATH%\chroma_data" mkdir "%PROJECT_PATH%\chroma_data"
start "ChromaDB" cmd /k "cd /d "%PROJECT_PATH%" && echo [CHROMADB] Running on port %CHROMA_PORT% && echo. && chroma run --path ./chroma_data --port %CHROMA_PORT%"
echo ChromaDB window opened - Check it for output
pause
goto menu

:launch_fastapi
cls
echo Starting FastAPI Backend on port %API_PORT%...
if not exist "%PROJECT_PATH%\backend\kernel.py" (
    echo ERROR: kernel.py not found
    pause
    goto menu
)
start "FastAPI" cmd /k "cd /d "%PROJECT_PATH%" && set REZ_KERNEL_PORT=%API_PORT% && echo [FASTAPI] Starting on port %API_PORT% && echo. && python backend\kernel.py"
echo FastAPI window opened - Check it for output
pause
goto menu

:view_logs
cls
echo ===================================================
echo   📋 LIVE LOG FILES
echo ===================================================
echo.
if exist "%LOGS_PATH%" (
    dir /b "%LOGS_PATH%\*.log" 2>nul
    if errorlevel 1 echo No log files found yet
) else (
    echo Logs directory not found
)
echo.
echo To view a log file, type: type %LOGS_PATH%\filename.log
echo.
pause
goto menu

:launch_searxng
cls
echo Starting SearXNG Web Search...
docker start searxng >nul 2>&1
if %errorlevel%==0 (
    echo [OK] SearXNG running at http://localhost:%SEARXNG_PORT%
) else (
    echo Creating new SearXNG container...
    docker run -d --name searxng -p %SEARXNG_PORT%:8080 searxng/searxng:latest
    if %errorlevel%==0 (
        echo [OK] SearXNG created and running
    ) else (
        echo [ERROR] Failed - Is Docker Desktop running?
    )
)
pause
goto menu

:launch_mcp
cls
echo Starting MCP Servers in WSL...
if exist "%PROJECT_PATH%\mcp_servers" (
    echo Killing old MCP processes...
    wsl -d %WSL_DISTRO% -e bash -c "pkill -f mcp_servers" >nul 2>&1
    
    echo Starting executive_mcp.py (visible)...
    start "MCP-Executive" wsl -d %WSL_DISTRO% bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && echo '[MCP-EXEC] Starting...' && python3 mcp_servers/executive_mcp.py"
    
    echo Starting system_mcp.py (visible)...
    start "MCP-System" wsl -d %WSL_DISTRO% bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && echo '[MCP-SYS] Starting...' && python3 mcp_servers/system_mcp.py"
    
    echo Starting process_mcp.py (visible)...
    start "MCP-Process" wsl -d %WSL_DISTRO% bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && echo '[MCP-PROC] Starting...' && python3 mcp_servers/process_mcp.py"
    
    echo Starting research_mcp.py (visible)...
    start "MCP-Research" wsl -d %WSL_DISTRO% bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && echo '[MCP-RESEARCH] Starting...' && python3 mcp_servers/research_mcp.py"
    
    echo Starting rag_pipeline.py (visible)...
    start "MCP-RAG" wsl -d %WSL_DISTRO% bash -c "cd /mnt/d/okiru-os/The\ Reztack\ OS && echo '[MCP-RAG] Starting...' && python3 mcp_servers/rag_pipeline.py"
    
    echo [OK] All MCP servers started - Check their windows
) else (
    echo [ERROR] MCP servers directory not found
)
pause
goto menu

:status
cls
echo ===================================================
echo   📊 SERVICE STATUS
echo ===================================================
echo.

:: Check ports - prioritize 3001 as primary
netstat -ano | findstr ":3001" | findstr "LISTENING" >nul
if %errorlevel%==0 (
    echo [OK] Next.js:   RUNNING on port 3001 (primary)
) else (
    netstat -ano | findstr ":3000" | findstr "LISTENING" >nul
    if %errorlevel%==0 (
        echo [OK] Next.js:   RUNNING on port 3000
    ) else (
        echo [OFF] Next.js:   OFFLINE
    )
)

netstat -ano | findstr ":%API_PORT%" | findstr "LISTENING" >nul && echo [OK] FastAPI:   RUNNING on port %API_PORT% || echo [OFF] FastAPI:   OFFLINE
netstat -ano | findstr ":%CHROMA_PORT%" | findstr "LISTENING" >nul && echo [OK] ChromaDB:  RUNNING on port %CHROMA_PORT% || echo [OFF] ChromaDB:  OFFLINE
netstat -ano | findstr ":11434" | findstr "LISTENING" >nul && echo [OK] Ollama:    RUNNING || echo [WARN] Ollama:    OFFLINE

:: Check Docker
docker ps 2>nul | findstr "searxng" >nul && echo [OK] SearXNG:   RUNNING || echo [WARN] SearXNG:   OFFLINE

:: Check HTML UI
if exist "%PROJECT_PATH%\public\rez-hive.html" (
    echo [OK] HTML UI:   INSTALLED at /rez-hive.html
) else (
    echo [WARN] HTML UI: Not installed (use option 17)
)

:: Check if windows are open
tasklist | findstr "python.exe" >nul && echo [OK] Python:    RUNNING || echo [WARN] Python:    STOPPED
tasklist | findstr "node.exe" >nul && echo [OK] Node:      RUNNING || echo [WARN] Node:      STOPPED

echo.
echo ACTIVE WINDOWS SHOULD INCLUDE:
echo - ChromaDB, FastAPI, Next.js, MCP-* (if launched)
echo.
pause
goto menu

:list_models
cls
echo ===================================================
echo   🤖 AVAILABLE OLLAMA MODELS
echo ===================================================
echo.
ollama list
echo.
pause
goto menu

:kill
cls
echo Stopping ALL services...
taskkill /F /IM python.exe >nul 2>&1
taskkill /F /IM node.exe >nul 2>&1
docker stop searxng >nul 2>&1
wsl -d %WSL_DISTRO% -e bash -c "pkill -f mcp_servers" >nul 2>&1

:: Also kill anything on API port specifically
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :%API_PORT% ^| findstr LISTENING') do (
    taskkill /F /PID %%a >nul 2>&1
)

echo [OK] All services stopped
pause
goto menu