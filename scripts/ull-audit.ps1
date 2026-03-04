# REZ HIVE Sovereign OS - Full Stack Audit
# Usage: .\scripts\full-audit.ps1

Write-Host "`n╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     REZ HIVE SOVEREIGN OS - FULL STACK AUDIT      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

$projectRoot = "D:\okiru-os\The Reztack OS"
$auditTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$report = @{
    Timestamp = $auditTime
    Frontend = @{}
    Backend = @{}
    APIEndpoints = @{}
    PythonFiles = @{}
    Dependencies = @{}
    Services = @{}
    Environment = @{}
    Issues = @()
}

# ═══════════════════════════════════════════════════════════════
# 1. FRONTEND AUDIT (TypeScript/React)
# ═══════════════════════════════════════════════════════════════
Write-Host "[1/7] FRONTEND STRUCTURE" -ForegroundColor Yellow

$tsFiles = Get-ChildItem -Path "$projectRoot/src" -Recurse -Include "*.ts","*.tsx" -ErrorAction SilentlyContinue
$report.Frontend.TotalFiles = $tsFiles.Count
Write-Host "  Total TS/TSX files: $($tsFiles.Count)" -ForegroundColor Cyan

# Check key files
$requiredFrontend = @(
    "src/app/page.tsx",
    "src/app/layout.tsx",
    "src/app/globals.css",
    "src/app/api/kernel/route.ts",
    "src/app/api/status/route.ts"
)

foreach ($file in $requiredFrontend) {
    $exists = Test-Path "$projectRoot\$file"
    $status = if ($exists) { "✓" } else { "✗" }
    $color = if ($exists) { "Green" } else { "Red" }
    Write-Host "  $status $file" -ForegroundColor $color
    $report.Frontend[$file] = $exists
    if (-not $exists) {
        $report.Issues += "Missing frontend file: $file"
    }
}

# Extract all fetch/API calls from frontend
Write-Host "`n  Scanning for API calls..." -ForegroundColor Gray
$apiCalls = Select-String -Path "$projectRoot/src/**/*.tsx" -Pattern "fetch\(['`"]\/api" -ErrorAction SilentlyContinue
$report.Frontend.APICalls = @()

if ($apiCalls) {
    $endpoints = @{}
    foreach ($call in $apiCalls) {
        $match = [regex]::Match($call.Line, "fetch\(['`"]([^'`"]+)['`"]")
        if ($match.Success) {
            $endpoint = $match.Groups[1].Value
            $endpoints[$endpoint] = ($endpoints[$endpoint] || 0) + 1
            $report.Frontend.APICalls += $endpoint
        }
    }
    
    Write-Host "  Found $($endpoints.Count) unique API endpoints called:" -ForegroundColor Cyan
    foreach ($ep in $endpoints.Keys) {
        Write-Host "    → $ep ($($endpoints[$ep]) calls)" -ForegroundColor Gray
    }
}

# ═══════════════════════════════════════════════════════════════
# 2. API ENDPOINTS AUDIT (Next.js Routes)
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[2/7] API ENDPOINTS (Next.js Routes)" -ForegroundColor Yellow

$routeFiles = Get-ChildItem -Path "$projectRoot/src/app/api" -Recurse -Filter "route.ts" -ErrorAction SilentlyContinue
$report.APIEndpoints.Total = $routeFiles.Count
$report.APIEndpoints.List = @()

Write-Host "  Found $($routeFiles.Count) route handlers:" -ForegroundColor Cyan
foreach ($route in $routeFiles) {
    $relativePath = $route.FullName.Replace("$projectRoot\", "")
    $apiPath = $relativePath.Replace("src/app", "").Replace("\route.ts", "").Replace("/", "")
    $content = Get-Content $route.FullName -Raw
    
    # Detect HTTP methods
    $methods = @()
    if ($content -match "export async function GET") { $methods += "GET" }
    if ($content -match "export async function POST") { $methods += "POST" }
    if ($content -match "export async function PUT") { $methods += "PUT" }
    if ($content -match "export async function DELETE") { $methods += "DELETE" }
    
    $endpointInfo = @{
        Path = $apiPath
        File = $relativePath
        Methods = $methods
        Imports = @()
    }
    
    # Extract imports
    $imports = Select-String -Path $route.FullName -Pattern "^import.*from ['`"]([^'`"]+)['`"]"
    foreach ($imp in $imports) {
        $match = [regex]::Match($imp.Line, "from ['`"]([^'`"]+)['`"]")
        if ($match.Success) {
            $endpointInfo.Imports += $match.Groups[1].Value
        }
    }
    
    $report.APIEndpoints.List += $endpointInfo
    Write-Host "  ✓ $apiPath [$($methods -join ', ')]" -ForegroundColor Green
    Write-Host "    Imports: $($endpointInfo.Imports.Count) modules" -ForegroundColor Gray
}

# ═══════════════════════════════════════════════════════════════
# 3. PYTHON BACKEND AUDIT
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[3/7] PYTHON BACKEND FILES" -ForegroundColor Yellow

$pyFiles = Get-ChildItem -Path "$projectRoot" -Recurse -Include "*.py" -ErrorAction SilentlyContinue | 
           Where-Object { $_.FullName -notmatch "node_modules|venv|__pycache__" }
$report.PythonFiles.Total = $pyFiles.Count
$report.PythonFiles.List = @()

Write-Host "  Found $($pyFiles.Count) Python files:" -ForegroundColor Cyan

$allImports = @{}
foreach ($pyFile in $pyFiles) {
    $relativePath = $pyFile.FullName.Replace("$projectRoot\", "")
    $content = Get-Content $pyFile.FullName -Raw
    
    # Extract imports
    $importLines = Select-String -Path $pyFile.FullName -Pattern "^(import |from ).*"
    $fileImports = @()
    foreach ($imp in $importLines) {
        $fileImports += $imp.Line.Trim()
        
        # Track all unique imports
        $moduleName = ($imp.Line -replace "^from\s+([^\s]+).*", '$1' -replace "^import\s+([^\s]+).*", '$1').Split('.')[0]
        $allImports[$moduleName] = ($allImports[$moduleName] || 0) + 1
    }
    
    $report.PythonFiles.List += @{
        Path = $relativePath
        Imports = $fileImports
        Size = (Get-Item $pyFile.FullName).Length
    }
}

Write-Host "`n  Top Python imports:" -ForegroundColor Cyan
$allImports.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 10 | ForEach-Object {
    Write-Host "    $($_.Name) ($($_.Value) uses)" -ForegroundColor Gray
}

# Check for critical imports
$criticalPy = @("fastapi", "uvicorn", "chromadb", "ollama", "requests", "pydantic", "aiohttp")
Write-Host "`n  Critical dependencies:" -ForegroundColor Cyan
foreach ($dep in $criticalPy) {
    if ($allImports.ContainsKey($dep)) {
        Write-Host "    ✓ $dep" -ForegroundColor Green
    } else {
        Write-Host "    ✗ $dep (NOT FOUND)" -ForegroundColor Red
        $report.Issues += "Missing Python import: $dep"
    }
}

# ═══════════════════════════════════════════════════════════════
# 4. DEPENDENCIES AUDIT (Node.js + Python)
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[4/7] DEPENDENCIES" -ForegroundColor Yellow

# Node.js
if (Test-Path "$projectRoot/package.json") {
    $packageJson = Get-Content "$projectRoot/package.json" | ConvertFrom-Json
    $report.Dependencies.Node = @{
        Total = ($packageJson.dependencies.PSObject.Properties.Count + $packageJson.devDependencies.PSObject.Properties.Count)
        Prod = $packageJson.dependencies.PSObject.Properties.Count
        Dev = $packageJson.devDependencies.PSObject.Properties.Count
    }
    
    Write-Host "  Node.js packages: $($report.Dependencies.Node.Total) total" -ForegroundColor Cyan
    Write-Host "    Production: $($report.Dependencies.Node.Prod)" -ForegroundColor Gray
    Write-Host "    Development: $($report.Dependencies.Node.Dev)" -ForegroundColor Gray
    
    # Check critical Node packages
    $criticalNode = @("next", "react", "react-dom", "lucide-react", "react-markdown", "remark-gfm")
    Write-Host "`n  Critical Node packages:" -ForegroundColor Cyan
    foreach ($pkg in $criticalNode) {
        $installed = Test-Path "$projectRoot/node_modules/$pkg"
        if ($installed) {
            Write-Host "    ✓ $pkg" -ForegroundColor Green
        } else {
            Write-Host "    ✗ $pkg (NOT INSTALLED)" -ForegroundColor Red
            $report.Issues += "Missing Node package: $pkg"
        }
    }
}

# Python
if (Test-Path "$projectRoot/requirements.txt") {
    $requirements = Get-Content "$projectRoot/requirements.txt" | Where-Object { $_ -notmatch "^#" -and $_.Trim() }
    $report.Dependencies.Python = $requirements.Count
    
    Write-Host "`n  Python packages: $($requirements.Count) in requirements.txt" -ForegroundColor Cyan
    
    # Check if installed
    $missing = @()
    foreach ($req in $requirements) {
        $pkg = ($req -split "==|>=|<=|>|<")[0].Trim()
        $check = pip show $pkg 2>&1
        if ($LASTEXITCODE -ne 0) {
            $missing += $pkg
        }
    }
    
    if ($missing.Count -gt 0) {
        Write-Host "    ✗ $($missing.Count) packages not installed:" -ForegroundColor Red
        $missing | ForEach-Object { Write-Host "      - $_" -ForegroundColor Gray }
        $report.Issues += "Missing Python packages: $($missing -join ', ')"
    } else {
        Write-Host "    ✓ All Python packages installed" -ForegroundColor Green
    }
}

# ═══════════════════════════════════════════════════════════════
# 5. SERVICES AUDIT (External Connections)
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[5/7] EXTERNAL SERVICES" -ForegroundColor Yellow

$services = @{
    "Ollama (11434)" = "http://localhost:11434/api/tags"
    "Next.js (3000)" = "http://localhost:3000"
    "ChromaDB (8000)" = "http://localhost:8000/api/v1/heartbeat"
    "SearXNG (8080)" = "http://localhost:8080/"
}

$report.Services = @{}
foreach ($svcName in $services.Keys) {
    $url = $services[$svcName]
    try {
        $response = Invoke-WebRequest -Uri $url -Method Get -TimeoutSec 3 -ErrorAction Stop
        $status = "ONLINE ($($response.StatusCode))"
        $color = "Green"
        $report.Services[$svcName] = $true
    } catch {
        $status = "OFFLINE"
        $color = "Red"
        $report.Services[$svcName] = $false
        $report.Issues += "Service offline: $svcName"
    }
    Write-Host "  $svcName : $status" -ForegroundColor $color
}

# Check Ollama models
Write-Host "`n  Ollama models installed:" -ForegroundColor Cyan
try {
    $models = ollama list 2>&1 | Select-String "^" | Select-Object -First 10
    foreach ($model in $models) {
        Write-Host "    → $model" -ForegroundColor Gray
    }
    $report.Services.OllamaModels = $models.Count
} catch {
    Write-Host "    ✗ Could not list Ollama models" -ForegroundColor Red
}

# ═══════════════════════════════════════════════════════════════
# 6. ENVIRONMENT VARIABLES AUDIT
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[6/7] ENVIRONMENT VARIABLES" -ForegroundColor Yellow

$envFiles = @(".env.local", ".env", "backend/.env")
$report.Environment = @{}

foreach ($envFile in $envFiles) {
    if (Test-Path "$projectRoot\$envFile") {
        $content = Get-Content "$projectRoot\$envFile" -Raw
        $report.Environment[$envFile] = $true
        
        Write-Host "  ✓ $envFile exists" -ForegroundColor Green
        
        # Check for required vars
        $requiredVars = @("OLLAMA_BASE_URL", "OLLAMA_MODEL", "SECRET_KEY")
        foreach ($var in $requiredVars) {
            if ($content -match $var) {
                Write-Host "    ✓ $var defined" -ForegroundColor Green
            } else {
                Write-Host "    ⚠ $var not defined" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "  ✗ $envFile not found" -ForegroundColor Yellow
        $report.Environment[$envFile] = $false
    }
}

# ═══════════════════════════════════════════════════════════════
# 7. WORKERS FOLDER AUDIT
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[7/7] WORKERS ARCHITECTURE" -ForegroundColor Yellow

$workersExists = Test-Path "$projectRoot/src/workers"
$apiWorkersExists = Test-Path "$projectRoot/src/app/api/workers"

Write-Host "  src/workers/ : $(if($workersExists){'✓ exists'}else{'✗ missing'})" -ForegroundColor $(if($workersExists){"Green"}else{"Yellow"})
Write-Host "  src/app/api/workers/ : $(if($apiWorkersExists){'✓ exists'}else{'✗ missing'})" -ForegroundColor $(if($apiWorkersExists){"Green"}else{"Yellow"})

$report.Workers = @{
    PureWorkers = $workersExists
    APIWorkers = $apiWorkersExists
    Separated = ($workersExists -and $apiWorkersExists)
}

if (-not $workersExists) {
    $report.Issues += "src/workers/ folder missing - business logic not separated"
}

# ═══════════════════════════════════════════════════════════════
# FINAL REPORT
# ═══════════════════════════════════════════════════════════════
Write-Host "`n╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                  AUDIT SUMMARY                     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "  Frontend Files:     $($report.Frontend.TotalFiles)" -ForegroundColor Cyan
Write-Host "  API Endpoints:      $($report.APIEndpoints.Total)" -ForegroundColor Cyan
Write-Host "  Python Files:       $($report.PythonFiles.Total)" -ForegroundColor Cyan
Write-Host "  Node Packages:      $($report.Dependencies.Node.Total)" -ForegroundColor Cyan
Write-Host "  Python Packages:    $($report.Dependencies.Python)" -ForegroundColor Cyan
Write-Host "  Services Online:    $(($report.Services.Values | Where-Object { $_ }).Count)/$($report.Services.Count)" -ForegroundColor Cyan
Write-Host "  Issues Found:       $($report.Issues.Count)" -ForegroundColor $(if($report.Issues.Count -eq 0){"Green"}else{"Red"})

if ($report.Issues.Count -gt 0) {
    Write-Host "`n  ISSUES:" -ForegroundColor Red
    foreach ($issue in $report.Issues) {
        Write-Host "    • $issue" -ForegroundColor Yellow
    }
}

# Export report
$reportPath = "$projectRoot\audit-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$report | ConvertTo-Json -Depth 10 | Out-File $reportPath -Encoding UTF8
Write-Host "`n  Full report exported to: $reportPath" -ForegroundColor Cyan

Write-Host "`n╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║              AUDIT COMPLETE                        ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan