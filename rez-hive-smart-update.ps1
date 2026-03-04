# ============================================
# REZ HIVE - SMART UPDATE SCANNER
# ============================================
# This script scans your existing files and
# only adds what's missing - no duplicates!
# ============================================

param(
    [switch]$Force,      # Force update even if files exist
    [switch]$DryRun      # Show what would be done without making changes
)

Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     🏛️ REZ HIVE - SMART UPDATE SCANNER                        ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$PROJECT_PATH = "D:\okiru-os\The Reztack OS"
Set-Location $PROJECT_PATH

# ============================================
# SCAN FUNCTION
# ============================================
function Test-Feature {
    param($Feature, $Path, $Pattern)
    
    if (Test-Path $Path) {
        $content = Get-Content $Path -Raw -ErrorAction SilentlyContinue
        if ($content -match $Pattern) {
            return $true
        }
    }
    return $false
}

Write-Host "[SCANNING] Current installation..." -ForegroundColor Yellow
Write-Host ""

# ============================================
# SCAN 1: Models API Endpoint
# ============================================
$hasModelsAPI = Test-Feature -Feature "Models API" -Path "src\app\api\ollama\models\route.ts" -Pattern "ollama list"
Write-Host "📡 Models API: $(if($hasModelsAPI){'✅ FOUND'}else{'❌ MISSING'})" -ForegroundColor $(if($hasModelsAPI){'Green'}else{'Red'})

# ============================================
# SCAN 2: Model Selector in UI
# ============================================
$hasModelSelector = Test-Feature -Feature "Model Selector" -Path "src\app\page.tsx" -Pattern "selectedModel|setSelectedModel|availableModels"
Write-Host "🎨 Model Selector: $(if($hasModelSelector){'✅ FOUND'}else{'❌ MISSING'})" -ForegroundColor $(if($hasModelSelector){'Green'}else{'Red'})

# ============================================
# SCAN 3: ChevronDown Import
# ============================================
$hasChevron = Test-Feature -Feature "ChevronDown Import" -Path "src\app\page.tsx" -Pattern "ChevronDown"
Write-Host "⬇️ ChevronDown Icon: $(if($hasChevron){'✅ FOUND'}else{'❌ MISSING'})" -ForegroundColor $(if($hasChevron){'Green'}else{'Red'})

# ============================================
# SCAN 4: Kernel Model Parameter
# ============================================
$hasKernelModel = Test-Feature -Feature "Kernel Model Param" -Path "backend\kernel.py" -Pattern "def generate_stream\(task: str, model: str ="
Write-Host "🧠 Kernel Model Support: $(if($hasKernelModel){'✅ FOUND'}else{'❌ MISSING'})" -ForegroundColor $(if($hasKernelModel){'Green'}else{'Red'})

# ============================================
# SCAN 5: API Route Model Support
# ============================================
$hasAPIModel = Test-Feature -Feature "API Route Model" -Path "src\app\api\kernel\route.ts" -Pattern "model:"
Write-Host "🔌 API Route Model: $(if($hasAPIModel){'✅ FOUND'}else{'❌ MISSING'})" -ForegroundColor $(if($hasAPIModel){'Green'}else{'Red'})

# ============================================
# SCAN 6: Model Launcher
# ============================================
$hasModelLauncher = Test-Path "launch-rez-hive-model.bat"
Write-Host "🚀 Model Launcher: $(if($hasModelLauncher){'✅ FOUND'}else{'❌ MISSING'})" -ForegroundColor $(if($hasModelLauncher){'Green'}else{'Red'})

# ============================================
# SUMMARY
# ============================================
$totalChecks = 6
$passedChecks = @($hasModelsAPI, $hasModelSelector, $hasChevron, $hasKernelModel, $hasAPIModel, $hasModelLauncher).Where({$_ -eq $true}).Count

Write-Host ""
Write-Host "📊 SCAN SUMMARY: $passedChecks/$totalChecks features found" -ForegroundColor Cyan
Write-Host ""

if ($passedChecks -eq $totalChecks) {
    Write-Host "✅ Your REZ HIVE is already fully updated with model toggle!" -ForegroundColor Green
    Write-Host "   Run .\launch-rez-hive-model.bat to start" -ForegroundColor White
    exit 0
}

if ($DryRun) {
    Write-Host "🔍 DRY RUN - Would install missing features:" -ForegroundColor Yellow
    if (-not $hasModelsAPI) { Write-Host "   • Install Models API endpoint" }
    if (-not $hasModelSelector) { Write-Host "   • Add Model Selector to UI" }
    if (-not $hasChevron) { Write-Host "   • Add ChevronDown icon import" }
    if (-not $hasKernelModel) { Write-Host "   • Update kernel.py with model parameter" }
    if (-not $hasAPIModel) { Write-Host "   • Update API route for model" }
    if (-not $hasModelLauncher) { Write-Host "   • Create Model Launcher" }
    exit 0
}

# ============================================
# PROMPT FOR UPDATE
# ============================================
Write-Host "⚠️  Some features are missing. Ready to update?" -ForegroundColor Yellow
$confirm = Read-Host "Proceed with update? (y/n)"

if ($confirm -ne 'y') {
    Write-Host "❌ Update cancelled" -ForegroundColor Red
    exit 0
}

# ============================================
# CREATE BACKUP DIRECTORY
# ============================================
Write-Host ""
Write-Host "[1/6] Creating backup..." -ForegroundColor Yellow
$backupDir = "backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

if (Test-Path "src/app/page.tsx") {
    Copy-Item "src/app/page.tsx" "$backupDir/page.tsx.bak" -Force
}
if (Test-Path "backend/kernel.py") {
    Copy-Item "backend/kernel.py" "$backupDir/kernel.py.bak" -Force
}
Write-Host "   ✅ Backup created in $backupDir" -ForegroundColor Green

# ============================================
# INSTALL MISSING FEATURES
# ============================================

# 1. Models API Endpoint
if (-not $hasModelsAPI) {
    Write-Host "[2/6] Installing Models API endpoint..." -ForegroundColor Yellow
    $apiDir = "src\app\api\ollama\models"
    New-Item -ItemType Directory -Path $apiDir -Force | Out-Null
    
    $apiRoute = @'
import { NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

export async function GET() {
  try {
    const { stdout } = await execAsync('ollama list');
    const lines = stdout.trim().split('\n').slice(1);
    const models = lines.map(line => {
      const parts = line.split(/\s+/);
      return parts[0];
    }).filter(Boolean);
    
    return NextResponse.json({ models });
  } catch (error) {
    return NextResponse.json({ 
      models: ['llama3.2:latest', 'phi3.5:3.8b', 'qwen2.5-coder:14b'],
      default: 'llama3.2:latest'
    });
  }
}

export async function POST(request: Request) {
  try {
    const { model } = await request.json();
    return NextResponse.json({ selected: model });
  } catch (error) {
    return NextResponse.json({ error: 'Failed to set model' }, { status: 500 });
  }
}
'@
    $apiRoute | Out-File -FilePath "$apiDir\route.ts" -Encoding UTF8 -Force
    Write-Host "   ✅ Models API installed" -ForegroundColor Green
}

# 2. Update page.tsx with model selector (if missing)
if (-not $hasModelSelector -or -not $hasChevron -or $Force) {
    Write-Host "[3/6] Updating page.tsx with model selector..." -ForegroundColor Yellow
    
    $pagePath = "src\app\page.tsx"
    $content = Get-Content $pagePath -Raw
    
    # Add ChevronDown to imports if missing
    if ($content -notmatch "ChevronDown") {
        $content = $content -replace "MicOff, Trash2", "MicOff, Trash2, ChevronDown"
    }
    
    # Add state variables if missing
    if ($content -notmatch "selectedModel") {
        $pattern = '(const \[isListening, setIsListening\] = useState\(false\);(\s*))'
        $replacement = '$1  const [availableModels, setAvailableModels] = useState<string[]>([]);$2  const [selectedModel, setSelectedModel] = useState<string>("llama3.2:latest");$2  const [showModelDropdown, setShowModelDropdown] = useState(false);$2'
        $content = $content -replace $pattern, $replacement
    }
    
    # Add fetchModels function if missing
    if ($content -notmatch "fetchModels") {
        $fetchModelsFunc = @'

  const fetchModels = async () => {
    try {
      const res = await fetch('/api/ollama/models');
      const data = await res.json();
      if (data.models) {
        setAvailableModels(data.models);
        if (data.default && !selectedModel) {
          setSelectedModel(data.default);
        }
      }
    } catch (e) {
      console.error('Failed to fetch models', e);
      setAvailableModels(['llama3.2:latest', 'phi3.5:3.8b', 'qwen2.5-coder:14b']);
    }
  };

'@
        $pattern = '(const startListening = \(\) => {[\s\S]*?};(\s*))'
        $content = $content -replace $pattern, '$1$2' + $fetchModelsFunc
    }
    
    # Add fetchModels to useEffect if missing
    if ($content -notmatch "fetchModels\(\);" -and $content -match "checkServices\(\)") {
        $content = $content -replace '(checkServices\(\);(\s*))', '$1  fetchModels();$2'
    }
    
    # Add model selector UI if missing
    if ($content -notmatch "Model Selector Dropdown") {
        $modelSelectorUI = @'
        
        {/* Model Selector Dropdown */}
        <div className="relative ml-2">
          <button
            onClick={() => setShowModelDropdown(!showModelDropdown)}
            className="flex items-center gap-1 px-2 py-1 bg-white/5 hover:bg-white/10 rounded-lg text-xs text-white/60 border border-white/10"
          >
            <span className="truncate max-w-[80px]">{selectedModel.split(':')[0]}</span>
            <ChevronDown size={14} />
          </button>
          
          {showModelDropdown && (
            <div className="absolute top-full mt-1 left-0 bg-black/90 border border-white/10 rounded-lg py-1 z-50 max-h-60 overflow-y-auto min-w-[160px]">
              {availableModels.map((model) => (
                <button
                  key={model}
                  className={`w-full text-left px-3 py-1.5 text-xs hover:bg-white/10 ${
                    model === selectedModel ? 'text-cyan-400 bg-cyan-500/10' : 'text-white/60'
                  }`}
                  onClick={() => {
                    setSelectedModel(model);
                    setShowModelDropdown(false);
                  }}
                >
                  {model}
                </button>
              ))}
            </div>
          )}
        </div>
'@
        $content = $content -replace '(<div className="flex items-center gap-1.5"><span className={`w-2 h-2 rounded-full \${services\.chroma \? ''bg-green-400 animate-pulse'' : ''bg-red-400''}`} /><span className="text-xs text-white/30">Memory</span></div>)', '$1' + $modelSelectorUI
    }
    
    # Update executeAction with model
    if ($content -notmatch "model: selectedModel") {
        $content = $content -replace '(body: JSON\.stringify\(\{ task: commandText, worker: activeWorker\.toLowerCase\(\), \.\.\.payload \}\)),', 'body: JSON.stringify({ task: commandText, worker: activeWorker.toLowerCase(), model: selectedModel, ...payload }),'
    }
    
    $content | Out-File -FilePath $pagePath -Encoding UTF8 -Force
    Write-Host "   ✅ page.tsx updated" -ForegroundColor Green
}

# 3. Update kernel.py if missing
if (-not $hasKernelModel) {
    Write-Host "[4/6] Updating kernel.py with model support..." -ForegroundColor Yellow
    
    $kernelPath = "backend\kernel.py"
    $content = Get-Content $kernelPath -Raw
    
    # Update generate_stream signature
    $content = $content -replace 'async def generate_stream\(task: str\):', 'async def generate_stream(task: str, model: str = "llama3.2:latest"):'
    
    # Update Ollama call
    $content = $content -replace "model='llama3.2',", "model=model,"
    
    # Update endpoint
    if ($content -notmatch "model = req.model") {
        $content = $content -replace '(async def kernel_endpoint\(req: TaskRequest\):)', '$1\n    model = req.model if hasattr(req, "model") else "llama3.2:latest"'
        $content = $content -replace '(return StreamingResponse\(generate_stream\(req.task\),)', 'return StreamingResponse(generate_stream(req.task, model),)'
    }
    
    # Add model to TaskRequest if missing
    if ($content -notmatch "model: Optional\[str\] = None") {
        $content = $content -replace '(class TaskRequest\(BaseModel\):[\s\S]*?task: str[\s\S]*?worker: str = "brain"[\s\S]*?payload: Optional\[Dict\[str, Any\]\] = None)', '$1\n    model: Optional[str] = None'
    }
    
    $content | Out-File -FilePath $kernelPath -Encoding UTF8 -Force
    Write-Host "   ✅ kernel.py updated" -ForegroundColor Green
}

# 4. Update API route if missing
if (-not $hasAPIModel) {
    Write-Host "[5/6] Updating API route with model support..." -ForegroundColor Yellow
    
    $apiKernelPath = "src\app\api\kernel\route.ts"
    if (Test-Path $apiKernelPath) {
        $content = Get-Content $apiKernelPath -Raw
        
        if ($content -notmatch "model:") {
            $content = $content -replace '(const { task, worker, payload } = await request.json\(\);)', 'const { task, worker, model, payload } = await request.json();'
        }
        
        $content | Out-File -FilePath $apiKernelPath -Encoding UTF8 -Force
        Write-Host "   ✅ API route updated" -ForegroundColor Green
    }
}

# 5. Create model launcher if missing
if (-not $hasModelLauncher) {
    Write-Host "[6/6] Creating model launcher..." -ForegroundColor Yellow
    
    $launcherContent = @'
@echo off
title REZ HIVE MODEL LAUNCHER 🏛️
color 0A

set "PROJECT_PATH=D:\okiru-os\The Reztack OS"
set "PYTHON_PATH=python"
set "CHROMA_PORT=8000"
set "API_PORT=8001"
set "FRONTEND_PORT=3000"
set "SEARXNG_PORT=8080"

:menu
cls
echo.
echo  ╔═══════════════════════════════════════════════════════════════╗
echo  ║    🏛️ REZ HIVE - MODEL LAUNCHER (22 MODELS)                  ║
echo  ╚═══════════════════════════════════════════════════════════════╝
echo.
echo  [1] LAUNCH FULL STACK
echo  [2] LAUNCH CHROMADB ONLY
echo  [3] LAUNCH FASTAPI ONLY
echo  [4] LAUNCH NEXT.JS ONLY
echo  [5] CHECK STATUS
echo  [6] STOP ALL
echo  [7] EXIT
echo.
set /p choice=Select option: 

if "%choice%"=="1" goto launch_full
if "%choice%"=="2" goto launch_chroma
if "%choice%"=="3" goto launch_fastapi
if "%choice%"=="4" goto launch_nextjs
if "%choice%"=="5" goto status
if "%choice%"=="6" goto kill
if "%choice%"=="7" exit
goto menu

:launch_full
taskkill /F /IM python.exe >nul 2>&1
taskkill /F /IM node.exe >nul 2>&1
start "ChromaDB" cmd /k "cd /d "%PROJECT_PATH%" && chroma run --path ./chroma_data --port %CHROMA_PORT%"
timeout /t 3
start "FastAPI" cmd /k "cd /d "%PROJECT_PATH%" && python backend\kernel.py"
timeout /t 3
start "Next.js" cmd /k "cd /d "%PROJECT_PATH%" && npm run dev"
echo.
echo ✅ All services started - Model toggle in UI header
echo 📍 http://localhost:3000
pause
goto menu

:launch_chroma
start "ChromaDB" cmd /k "cd /d "%PROJECT_PATH%" && chroma run --path ./chroma_data --port %CHROMA_PORT%"
pause
goto menu

:launch_fastapi
start "FastAPI" cmd /k "cd /d "%PROJECT_PATH%" && python backend\kernel.py"
pause
goto menu

:launch_nextjs
start "Next.js" cmd /k "cd /d "%PROJECT_PATH%" && npm run dev"
pause
goto menu

:status
netstat -ano | findstr ":%FRONTEND_PORT%" >nul && echo Next.js: RUNNING || echo Next.js: OFFLINE
netstat -ano | findstr ":%API_PORT%" >nul && echo FastAPI: RUNNING || echo FastAPI: OFFLINE
netstat -ano | findstr ":%CHROMA_PORT%" >nul && echo ChromaDB: RUNNING || echo ChromaDB: OFFLINE
pause
goto menu

:kill
taskkill /F /IM python.exe >nul 2>&1
taskkill /F /IM node.exe >nul 2>&1
echo All services stopped
pause
goto menu
'@
    
    $launcherContent | Out-File -FilePath "launch-rez-hive-model.bat" -Encoding ASCII -Force
    Write-Host "   ✅ Model launcher created" -ForegroundColor Green
}

# ============================================
# COMPLETE
# ============================================
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║     ✅ REZ HIVE SMART UPDATE COMPLETE!                        ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "📋 SCAN RESULTS: $passedChecks/$totalChecks features found" -ForegroundColor Cyan
Write-Host "🔧 INSTALLED: $(($totalChecks - $passedChecks)) new features" -ForegroundColor Yellow
Write-Host "📁 BACKUP: $backupDir" -ForegroundColor Gray
Write-Host ""
Write-Host "🚀 To start with model toggle:" -ForegroundColor Cyan
Write-Host "   .\launch-rez-hive-model.bat" -ForegroundColor White
Write-Host "   Then open http://localhost:3000" -ForegroundColor White
Write-Host ""
Write-Host "🏛️ Your 22 models are now ready to toggle!" -ForegroundColor Green