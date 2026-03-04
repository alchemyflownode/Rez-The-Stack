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
echo    2. START MINIMAL       (Server Only)
echo    3. STOP ALL SERVICES
echo    4. RESTART STACK
echo    5. CLEAN CACHE
echo    6. STATUS CHECK
echo    7. PULL MODEL (llama3.2:3b)
echo    8. CHROMADB TOOLS
echo    9. EXIT
echo.
echo ========================================
set /p "choice=Select Option [1-9]: "

if "%choice%"=="1" goto fullstack
if "%choice%"=="2" goto start
if "%choice%"=="3" goto stop
if "%choice%"=="4" goto restart
if "%choice%"=="5" goto clean
if "%choice%"=="6" goto status
if "%choice%"=="7" goto pull
if "%choice%"=="8" goto chroma_menu
if "%choice%"=="9" exit
goto menu

:fullstack
cls
echo.
echo [START] Awakening FULL Sovereign Stack...
echo.

:: Start ChromaDB using Python script
echo [1/6] Starting ChromaDB Memory Server...
start "ChromaDB Memory" cmd /k "%PYTHON_PATH% chroma_server.py"
timeout /t 3 /nobreak >nul

:: Rest of the stack
goto start_common

:start
cls
echo.
echo [START] Awakening Sovereign Stack...
echo.
goto start_common

:start_common
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

echo [2/5] Clearing Ports 3000/3001/8000...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3000') do (
    if not "%%a"=="" taskkill /PID %%a /F >nul 2>&1
)
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3001') do (
    if not "%%a"=="" taskkill /PID %%a /F >nul 2>&1
)
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8000') do (
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
echo   ✅ SOVEREIGN STACK ONLINE
echo   📍 Dashboard: http://localhost:3000
echo   💾 Memory: ChromaDB on port 8000
echo   🧠 Brain: Ollama on port 11434
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
echo [STOP] Shutting down sovereign services...
echo.

:: Kill all related processes
echo Killing Node.js processes...
for /f "tokens=2" %%a in ('tasklist ^| findstr /i "node.exe"') do (
    taskkill /PID %%a /F >nul 2>&1
)

echo Killing Python (ChromaDB) processes...
for /f "tokens=2" %%a in ('tasklist ^| findstr /i "python.exe"') do (
    taskkill /PID %%a /F >nul 2>&1
)

:: Kill specific ports
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3000') do (
    if not "%%a"=="" taskkill /PID %%a /F >nul 2>&1
)
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3001') do (
    if not "%%a"=="" taskkill /PID %%a /F >nul 2>&1
)
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8000') do (
    if not "%%a"=="" taskkill /PID %%a /F >nul 2>&1
)

echo   ✅ All sovereign services stopped.
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
goto fullstack

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
    echo   ✅ Next.js cache purged.
)

if exist "node_modules\.cache" (
    rmdir /s /q "node_modules\.cache"
    echo   ✅ Module cache purged.
)

if exist "chroma_data" (
    echo   ⚠️  ChromaDB data found. Purge? (y/n)
    set /p "purge_chroma="
    if /i "!purge_chroma!"=="y" (
        rmdir /s /q chroma_data
        echo   ✅ ChromaDB data purged.
    )
)

echo.
pause
goto menu

:chroma_menu
cls
echo.
echo  ============== CHROMADB TOOLS ==============
echo.
echo    1. START CHROMADB SERVER
echo    2. TEST CHROMADB CONNECTION
echo    3. VIEW COLLECTIONS
echo    4. VIEW MEMORY STATS
echo    5. PURGE ALL MEMORY
echo    6. BACK TO MAIN MENU
echo.
echo ========================================
set /p "chroma_choice=Select Option [1-6]: "

if "%chroma_choice%"=="1" goto chroma_start
if "%chroma_choice%"=="2" goto chroma_test
if "%chroma_choice%"=="3" goto chroma_list
if "%chroma_choice%"=="4" goto chroma_stats
if "%chroma_choice%"=="5" goto chroma_purge
if "%chroma_choice%"=="6" goto menu
goto chroma_menu

:chroma_start
cls
echo.
echo [CHROMADB] Starting Memory Server...
echo.
start "ChromaDB Memory" cmd /k "%PYTHON_PATH% chroma_server.py"
echo.
echo ✅ ChromaDB started in new window
pause
goto chroma_menu

:chroma_test
cls
echo.
echo [CHROMADB] Testing Connection...
%PYTHON_PATH% -c "
import chromadb
print('ChromaDB version:', chromadb.__version__)

client = chromadb.PersistentClient(path='./chroma_data')
print('✅ Client created')

collection = client.get_or_create_collection('test_collection')
print('✅ Collection ready')

collection.add(
    ids=['test1'],
    documents=['REZ HIVE is sovereign']
)
print('✅ Document added')

results = collection.query(
    query_texts=['sovereign'],
    n_results=1
)
print('✅ Query successful')
print('📊 Result:', results['documents'][0][0])

client.delete_collection('test_collection')
print('✅ Test collection cleaned up')
"
echo.
pause
goto chroma_menu

:chroma_list
cls
echo.
echo [CHROMADB] Viewing Collections...
%PYTHON_PATH% -c "
import chromadb
client = chromadb.PersistentClient(path='./chroma_data')
collections = client.list_collections()
print(f'\n📚 Found {len(collections)} collections:\n')
if len(collections) == 0:
    print('   No collections yet.')
else:
    for col in collections:
        print(f'   • {col.name}: {col.count()} vectors')
"
echo.
pause
goto chroma_menu

:chroma_stats
cls
echo.
echo [CHROMADB] Memory Statistics...
%PYTHON_PATH% -c "
import chromadb
import os

client = chromadb.PersistentClient(path='./chroma_data')
collections = client.list_collections()

print('\n📊 REZ HIVE MEMORY STATISTICS')
print('='*40)
print(f'ChromaDB Version: {chromadb.__version__}')
print(f'Data Path: {os.path.abspath("./chroma_data")}')
print(f'Total Collections: {len(collections)}')
print('='*40)

total_vectors = 0
for col in collections:
    count = col.count()
    total_vectors += count
    print(f'📚 {col.name}: {count} vectors')

print('='*40)
print(f'📈 TOTAL VECTORS: {total_vectors}')
print('='*40)
"
echo.
pause
goto chroma_menu

:chroma_purge
cls
echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║     ⚠️  DANGER: MEMORY PURGE WARNING                         ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
echo This will DELETE ALL stored memories permanently!
echo.
%PYTHON_PATH% -c "
import chromadb
client = chromadb.PersistentClient(path='./chroma_data')
cols = client.list_collections()
total = 0
for col in cols:
    total += col.count()
print(f'📊 Current memories: {total} vectors across {len(cols)} collections')
"
echo.
set /p "confirm=Type 'PURGE' to confirm: "
if "%confirm%"=="PURGE" (
    echo.
    echo Purging memory...
    rmdir /s /q chroma_data >nul 2>&1
    mkdir chroma_data >nul 2>&1
    echo ✅ All memories purged.
    echo.
    echo Recreating fresh memory collection...
    %PYTHON_PATH% -c "
import chromadb
client = chromadb.PersistentClient(path='./chroma_data')
collection = client.create_collection('rez_hive_memory')
print('✅ Fresh memory collection created')
" 2>nul
) else (
    echo ❌ Purge cancelled.
)
echo.
pause
goto chroma_menu

:status
cls
echo.
echo ============== SOVEREIGN STATUS ==============
echo.

echo --- Port 3000 (Next.js UI) ---
netstat -ano | findstr :3000
echo.

echo --- Port 8000 (ChromaDB Memory) ---
netstat -ano | findstr :8000
echo.

echo --- Node Processes ---
tasklist | findstr /i "node.exe"
echo.

echo --- Python Processes ---
tasklist | findstr /i "python.exe"
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
echo --- ChromaDB Status ---
%PYTHON_PATH% -c "
import chromadb
try:
    client = chromadb.PersistentClient(path='./chroma_data')
    collections = client.list_collections()
    total = 0
    for col in collections:
        total += col.count()
    print('ChromaDB: ✅ ONLINE')
    print(f'Collections: {len(collections)}')
    print(f'Total Vectors: {total}')
    for col in collections:
        print(f'  • {col.name}: {col.count()} vectors')
except Exception as e:
    print('ChromaDB: ❌ OFFLINE')
" 2>nul

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
echo    - Python installed
pause
goto menu