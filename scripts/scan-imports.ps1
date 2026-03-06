# scan-imports.ps1
Write-Host "🔍 REZ HIVE - COMPLETE IMPORT & ENDPOINT SCAN" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

$PROJECT_PATH = "D:\okiru-os\The Reztack OS"
Set-Location $PROJECT_PATH

# ============================================
# 1. SCAN NEXT.JS PAGES/API ENDPOINTS
# ============================================
Write-Host "[1/5] Scanning Next.js endpoints..." -ForegroundColor Yellow

$nextEndpoints = @()
Get-ChildItem -Path "src\app" -Recurse -Include "*.tsx","*.ts","*.js" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match "export (async )?function (GET|POST|PUT|DELETE|PATCH)") {
        $method = $matches[2]
        $relativePath = $_.FullName.Replace($PROJECT_PATH, "").Replace("\", "/")
        $endpoint = $relativePath -replace "src/app", "" -replace "/route\.tsx?", "" -replace "/route\.ts", ""
        $nextEndpoints += [PSCustomObject]@{
            Type = "Next.js API"
            Method = $method
            Endpoint = $endpoint
            File = $relativePath
        }
        Write-Host "   📡 $method $endpoint" -ForegroundColor Green
    }
}

# ============================================
# 2. SCAN FASTAPI ENDPOINTS (Python backend)
# ============================================
Write-Host "`n[2/5] Scanning FastAPI endpoints..." -ForegroundColor Yellow

$fastapiEndpoints = @()
if (Test-Path "backend") {
    Get-ChildItem -Path "backend" -Recurse -Include "*.py" | ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        # Look for FastAPI decorators
        $pattern = '@app\.(get|post|put|delete|patch)\(["'']([^"'']+)["'']'
        $matches = [regex]::Matches($content, $pattern)
        foreach ($match in $matches) {
            $method = $match.Groups[1].Value.ToUpper()
            $endpoint = $match.Groups[2].Value
            $relativePath = $_.FullName.Replace($PROJECT_PATH, "").Replace("\", "/")
            $fastapiEndpoints += [PSCustomObject]@{
                Type = "FastAPI"
                Method = $method
                Endpoint = $endpoint
                File = $relativePath
            }
            Write-Host "   🐍 $method $endpoint" -ForegroundColor Green
        }
    }
}

# ============================================
# 3. SCAN FRONTEND API CALLS (where endpoints are used)
# ============================================
Write-Host "`n[3/5] Scanning frontend API calls..." -ForegroundColor Yellow

$apiCalls = @()
Get-ChildItem -Path "src" -Recurse -Include "*.tsx","*.ts","*.js","*.jsx" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    # Look for fetch calls
    $pattern = 'fetch\([''"]`$?{?([^''"{}]*)[''"]'
    $matches = [regex]::Matches($content, $pattern)
    foreach ($match in $matches) {
        $url = $match.Groups[1].Value
        if ($url -match "^/api/") {
            $relativePath = $_.FullName.Replace($PROJECT_PATH, "").Replace("\", "/")
            $apiCalls += [PSCustomObject]@{
                Type = "API Call"
                URL = $url
                File = $relativePath
            }
            Write-Host "   📞 $url in $relativePath" -ForegroundColor Yellow
        }
    }
}

# ============================================
# 4. SCAN IMPORTS (dependency graph)
# ============================================
Write-Host "`n[4/5] Scanning imports..." -ForegroundColor Yellow

$imports = @{}
Get-ChildItem -Path "src" -Recurse -Include "*.tsx","*.ts","*.js","*.jsx","*.py" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $relativePath = $_.FullName.Replace($PROJECT_PATH, "").Replace("\", "/")
    
    # TypeScript/React imports
    if ($_.Extension -match "tsx?|jsx?") {
        $tsImports = [regex]::Matches($content, 'import .+ from [''"]([^''"]+)[''"]')
        foreach ($imp in $tsImports) {
            $imported = $imp.Groups[1].Value
            $imports[$imported] = $imports[$imported] + 1
        }
    }
    
    # Python imports
    if ($_.Extension -eq ".py") {
        $pyImports = [regex]::Matches($content, '^(from|import) (\S+)', 'MultiLine')
        foreach ($imp in $pyImports) {
            $imported = $imp.Groups[2].Value
            $imports[$imported] = $imports[$imported] + 1
        }
    }
}

Write-Host "   📦 Found $($imports.Count) unique imports" -ForegroundColor Green

# ============================================
# 5. CHECK PROXY CONFIGURATION
# ============================================
Write-Host "`n[5/5] Checking proxy configuration..." -ForegroundColor Yellow

if (Test-Path "next.config.js") {
    $content = Get-Content "next.config.js" -Raw
    if ($content -match "rewrites") {
        Write-Host "   ✅ next.config.js has rewrites configured" -ForegroundColor Green
        # Extract proxy mappings
        $proxyMatches = [regex]::Matches($content, "source: ['""]([^'""]+)['""],\s*destination: ['""]([^'""]+)['""]")
        foreach ($match in $proxyMatches) {
            Write-Host "      🔄 $($match.Groups[1].Value) → $($match.Groups[2].Value)" -ForegroundColor Cyan
        }
    } else {
        Write-Host "   ⚠️  No rewrites found in next.config.js" -ForegroundColor Yellow
    }
}

if (Test-Path "src/proxy.ts") {
    Write-Host "   📄 src/proxy.ts exists" -ForegroundColor Green
}

# ============================================
# SUMMARY
# ============================================
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     📊 IMPORT & ENDPOINT SUMMARY                              ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "Next.js API Endpoints: $($nextEndpoints.Count)" -ForegroundColor White
$nextEndpoints | Format-Table -AutoSize

Write-Host "FastAPI Endpoints: $($fastapiEndpoints.Count)" -ForegroundColor White
$fastapiEndpoints | Format-Table -AutoSize

Write-Host "Frontend API Calls: $($apiCalls.Count)" -ForegroundColor White
$apiCalls | Group-Object URL | Select-Object Name, Count | Format-Table -AutoSize

Write-Host "Top 10 Most Imported Packages:" -ForegroundColor White
$imports.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 10 | Format-Table -AutoSize

# ============================================
# ENDPOINT MAPPING (What's connected to what)
# ============================================
Write-Host ""
Write-Host "🔗 ENDPOINT MAPPING" -ForegroundColor Magenta
Write-Host "===================" -ForegroundColor Magenta

# Map frontend calls to backend endpoints
foreach ($call in $apiCalls) {
    $matched = $false
    foreach ($endpoint in $fastapiEndpoints) {
        if ($call.URL -like "*$($endpoint.Endpoint)*") {
            Write-Host "✅ $($call.URL) → FastAPI:$($endpoint.Method) $($endpoint.Endpoint)" -ForegroundColor Green
            $matched = $true
            break
        }
    }
    if (-not $matched) {
        foreach ($endpoint in $nextEndpoints) {
            if ($call.URL -like "*$($endpoint.Endpoint)*") {
                Write-Host "📡 $($call.URL) → Next.js:$($endpoint.Method) $($endpoint.Endpoint)" -ForegroundColor Cyan
                $matched = $true
                break
            }
        }
    }
    if (-not $matched) {
        Write-Host "❌ $($call.URL) → No matching endpoint found!" -ForegroundColor Red
    }
}

# ============================================
# SAVE REPORT
# ============================================
$report = @"
REZ HIVE - IMPORT & ENDPOINT SCAN
Date: $(Get-Date)
================================

NEXT.JS ENDPOINTS:
$($nextEndpoints | Out-String)

FASTAPI ENDPOINTS:
$($fastapiEndpoints | Out-String)

FRONTEND API CALLS:
$($apiCalls | Out-String)

PROXY CONFIG:
$(Get-Content "next.config.js" -Raw 2>$null)

IMPORT STATS:
$($imports.GetEnumerator() | Sort-Object Value -Descending | Out-String)
"@

$report | Out-File -FilePath "import_scan_report.txt" -Encoding UTF8 -Force
Write-Host ""
Write-Host "📄 Full report saved to: import_scan_report.txt" -ForegroundColor Yellow