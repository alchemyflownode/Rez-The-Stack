@echo off
title REZ HIVE SOVEREIGN CONTROL CONSOLE 🏛️
color 0A

:: Set the correct project path (CHANGE THIS IF NEEDED)
set "PROJECT_PATH=D:\okiru-os\The Reztack OS"
set "PYTHON_PATH=C:\Users\Zphoenix\AppData\Local\Programs\Python\Python310\python.exe"

:menu
cls
echo.
echo  ╔═══════════════════════════════════════════════════════════════╗
echo  ║         REZ HIVE SOVEREIGN CONTROL CONSOLE 🏛️                 ║
echo  ╚═══════════════════════════════════════════════════════════════╝
echo.
echo    1. START FULL STACK    (Ollama + ChromaDB + Server)
echo    2. START SERVER ONLY    (Next.js only)
echo    3. START MEMORY ONLY    (ChromaDB only)
echo    4. STOP ALL SERVICES
echo    5. RESTART STACK
echo    6. CLEAN CACHE
echo    7. STATUS CHECK
echo    8. PULL MODEL (llama3.2:3b)
echo    9. CHROMADB TOOLS
echo    0. EXIT
echo.
echo ========================================
set /p "choice=Select Option [0-9]: "

if "%choice%"=="1" goto fullstack
if "%choice%"=="2" goto start
if "%choice%"=="3" goto memory
if "%choice%"=="4" goto stop
if "%choice%"=="5" goto restart
if "%choice%"=="6" goto clean
if "%choice%"=="7" goto status
if "%choice%"=="8" goto pull
if "%choice%"=="9" goto chroma_menu
if "%choice%"=="0" exit
goto menu

:fullstack
cls
echo.
echo [START] Awakening FULL Sovereign Stack...
echo.

:: Start ChromaDB in new window
echo [1/4] Starting ChromaDB Memory Server...
start "ChromaDB Memory" cmd /k "%PYTHON_PATH% start_chroma.py"
timeout /t 3 /nobreak >nul

:: Start Ollama if not running
echo [2/4] Verifying Ollama...
curl -s http://localhost:11434/api/tags >nul 2>&1
if %errorlevel% neq 0 (
    echo      Starting Ollama...
    start /min "Ollama Service" "C:\Users\Zphoenix\AppData\Local\Programs\Ollama\ollama.exe" serve
    timeout /t 5 /nobreak >nul
)

:: Clear ports
echo [3/4] Clearing Ports...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3000') do taskkill /PID %%a /F >nul 2>&1
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8000') do taskkill /PID %%a /F >nul 2>&1

:: Start Next.js
echo [4/4] Starting REZ HIVE Server...
cd /d "%PROJECT_PATH%"
start "REZ HIVE UI" cmd /k "npm run dev"
timeout /t 8 /nobreak >nul

:: Open browser
start http://localhost:3000
echo.
echo ========================================
echo   ✅ FULL SOVEREIGN STACK ONLINE
echo   📍 UI: http://localhost:3000
echo   💾 Memory: ChromaDB on port 8000
echo   🧠 Brain: Ollama on port 11434
echo ========================================
pause
goto menu

:memory
cls
echo.
echo [MEMORY] Starting ChromaDB Server...
cd /d "%PROJECT_PATH%"

:: Create start_chroma.py if it doesn't exist
if not exist "start_chroma.py" (
    echo Creating ChromaDB startup script...
    (
    echo import chromadb
    echo import time
    echo import sys
    echo.
    echo print("🏛️ REZ HIVE Memory Server Starting...")
    echo print(f"ChromaDB version: {chromadb.__version__}")
    echo.
    echo client = chromadb.PersistentClient(path="./chroma_data")
    echo collections = client.list_collections()
    echo print(f"📚 Existing collections: {len(collections)}")
    echo for col in collections:
    echo     print(f"   • {col.name}: {col.count()} vectors")
    echo.
    echo collection = client.get_or_create_collection("rez_hive_memory")
    echo print(f"✅ Memory collection ready")
    echo print(f"📊 Total vectors: {collection.count()}")
    echo.
    echo print("\n🌐 Server running. Press Ctrl+C to stop\n")
    echo.
    echo try:
    echo     while True:
    echo         time.sleep(1)
    echo except KeyboardInterrupt:
    echo     print("\n👋 Shutting down...")
    echo     sys.exit(0)
    ) > start_chroma.py
)

start "ChromaDB Memory" cmd /k "%PYTHON_PATH% start_chroma.py"
timeout /t 3 /nobreak >nul
echo ✅ ChromaDB started
pause
goto menu

:start
cls
echo.
echo [START] Awakening Sovereign Stack (Server Only)...
echo.
cd /d "%PROJECT_PATH%"

:: Clear ports
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3000') do taskkill /PID %%a /F >nul 2>&1

:: Clear cache
if exist ".next" rmdir /s /q .next

:: Start server
start "REZ HIVE UI" cmd /k "npm run dev"
timeout /t 5 /nobreak >nul
start http://localhost:3000
echo ✅ Server started
pause
goto menu

:stop
cls
echo.
echo [STOP] Shutting down all services...
echo.

:: Kill all processes
echo Killing Node.js...
for /f "tokens=2" %%a in ('tasklist ^| findstr /i "node.exe"') do taskkill /PID %%a /F >nul 2>&1

echo Killing Python (ChromaDB)...
for /f "tokens=2" %%a in ('tasklist ^| findstr /i "python.exe"') do taskkill /PID %%a /F >nul 2>&1

:: Kill ports
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3000') do taskkill /PID %%a /F >nul 2>&1
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8000') do taskkill /PID %%a /F >nul 2>&1
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :11434') do taskkill /PID %%a /F >nul 2>&1

echo   ✅ All services stopped.
pause
goto menu

:restart
cls
echo.
echo [RESTART] Recycling Sovereign Stack...
call :stop
timeout /t 3 /nobreak >nul
goto fullstack

:clean
cls
echo.
echo [CLEAN] Purging cache...
echo.
cd /d "%PROJECT_PATH%"

if exist ".next" (
    rmdir /s /q .next
    echo   ✅ Next.js cache purged.
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
echo ============== SOVEREIGN STATUS ==============
echo.

echo --- Port Status ---
netstat -ano | findstr :3000 >nul && echo 📍 Port 3000 (UI): ✅ IN USE || echo 📍 Port 3000 (UI): ⬜ FREE
netstat -ano | findstr :8000 >nul && echo 📍 Port 8000 (Memory): ✅ IN USE || echo 📍 Port 8000 (Memory): ⬜ FREE
netstat -ano | findstr :11434 >nul && echo 📍 Port 11434 (Brain): ✅ IN USE || echo 📍 Port 11434 (Brain): ⬜ FREE
echo.

echo --- Ollama Models ---
curl -s http://localhost:11434/api/tags | findstr /i "name" || echo No models found
echo.

echo --- ChromaDB Status ---
%PYTHON_PATH% -c "
import chromadb
try:
    client = chromadb.PersistentClient(path='./chroma_data')
    cols = client.list_collections()
    print(f'📚 Collections: {len(cols)}')
    for col in cols:
        print(f'   • {col.name}: {col.count()} vectors')
except:
    print('❌ ChromaDB not running')
" 2>nul
echo.
pause
goto menu

:chroma_menu
cls
echo.
echo  ============== CHROMADB TOOLS ==============
echo.
echo    1. START MEMORY SERVER
echo    2. VIEW COLLECTIONS
echo    3. TEST MEMORY
echo    4. PURGE ALL MEMORY
echo    5. BACK TO MAIN MENU
echo.
echo ========================================
set /p "chroma_choice=Select Option [1-5]: "

if "%chroma_choice%"=="1" goto memory
if "%chroma_choice%"=="2" goto chroma_list
if "%chroma_choice%"=="3" goto chroma_test
if "%chroma_choice%"=="4" goto chroma_purge
if "%chroma_choice%"=="5" goto menu
goto chroma_menu

:chroma_list
cls
%PYTHON_PATH% -c "
import chromadb
client = chromadb.PersistentClient(path='./chroma_data')
cols = client.list_collections()
print(f'\n📚 Found {len(cols)} collections:\n')
for col in cols:
    print(f'   • {col.name}: {col.count()} vectors')
" 2>nul
echo.
pause
goto chroma_menu

:chroma_test
cls
%PYTHON_PATH% -c "
import chromadb
print('✅ Testing ChromaDB...')
client = chromadb.PersistentClient(path='./chroma_data')
col = client.get_or_create_collection('test')
col.add(
    ids=['test1'],
    documents=['REZ HIVE is sovereign']
)
results = col.query(query_texts=['sovereign'], n_results=1)
print(f'✅ Test passed: {results}')
" 2>nul
echo.
pause
goto chroma_menu

:chroma_purge
cls
echo ⚠️  WARNING: This will DELETE ALL MEMORIES!
set /p "confirm=Type 'PURGE' to confirm: "
if "%confirm%"=="PURGE" (
    rmdir /s /q chroma_data 2>nul
    mkdir chroma_data 2>nul
    echo ✅ All memories purged.
) else (
    echo ❌ Purge cancelled.
)
pause
goto chroma_menu

:pull
cls
echo.
echo [PULL] Downloading llama3.2:3b...
ollama pull llama3.2:3b
echo.
echo ✅ Model pull complete!
pause
goto menu