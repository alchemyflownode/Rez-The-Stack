# fix-okiru-simple.ps1
# Auto-fixes JSX syntax error in src/app/page.tsx

param(
    [string]$ProjectPath = "G:\okiru\app builder\Cognitive Kernel",
    [int]$Port = 3001
)

Push-Location $ProjectPath
Write-Host "[OKIRU] Starting auto-fix..." -ForegroundColor Cyan

# =============================================================================
# STEP 1: Kill processes on port
# =============================================================================
Write-Host "[1/5] Killing processes on port $Port..." -ForegroundColor Gray
try {
    $conn = Get-NetTCPConnection -LocalPort $Port -ErrorAction Stop
    $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
    if ($proc) { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue }
} catch {}
Get-Process -Name "node","bun" -ErrorAction SilentlyContinue | 
    Where-Object { $_.Path -like "*okiru*" } | 
    Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

# =============================================================================
# STEP 2: Fix JSX - line-by-line replacement (simple & reliable)
# =============================================================================
Write-Host "[2/5] Fixing JSX syntax in page.tsx..." -ForegroundColor Gray
$filePath = "src\app\page.tsx"
$lines = Get-Content $filePath
$fixed = @()
$inAssistantBlock = $false

foreach ($line in $lines) {
    # Track assistant message block
    if ($line -match "msg\.role === 'assistant'") { $inAssistantBlock = $true }
    
    # TARGET: The broken nested JSX expression on line ~289
    # Broken: {msg.stats ? <PCDashboard ... /> : <pre ...>{msg.content}</pre>}
    if ($inAssistantBlock -and $line -match '\{msg\.stats \?') {
        Write-Host "  🔧 Found broken line, replacing..." -ForegroundColor Yellow
        
        # Build the fixed line: flat ternary, no nested {}
        $fixedLine = '                      msg.stats ? ('
        $fixed += $fixedLine
        $fixed += '                        <PCDashboard stats={msg.stats} />'
        $fixed += '                      ) : msg.results && msg.results.length > 0 ? ('
        $fixed += '                        <SearchResults results={msg.results} />'
        $fixed += '                      ) : msg.answer ? ('
        $fixed += '                        <SearchResults answer={msg.answer} sources={msg.sources} />'
        $fixed += '                      ) : msg.content ? ('
        $fixed += '                        <pre className="text-sm text-gray-300 whitespace-pre-wrap font-mono">{msg.content}</pre>'
        $fixed += '                      ) : ('
        $fixed += '                        <span className="text-sm text-gray-400">No content</span>'
        $fixed += '                      )'
        
        $inAssistantBlock = $false  # Reset after fixing
        continue
    }
    
    # Skip the old broken sub-lines that we just replaced
    if ($inAssistantBlock -and ($line -match 'SearchResults.*msg\.answer' -or $line -match '<pre className.*msg\.content' -or $line -match '^\s*\)\}')) {
        continue
    }
    
    $fixed += $line
}

# Write fixed content
Set-Content -Path $filePath -Value $fixed -Encoding UTF8
Write-Host "  ✅ JSX fix applied" -ForegroundColor Green

# =============================================================================
# STEP 3: Clear cache
# =============================================================================
Write-Host "[3/5] Clearing Next.js cache..." -ForegroundColor Gray
if (Test-Path ".next") { Remove-Item -Recurse -Force ".next" -ErrorAction SilentlyContinue }

# =============================================================================
# STEP 4: Start server
# =============================================================================
Write-Host "[4/5] Starting dev server..." -ForegroundColor Gray
$env:NEXT_TURBOPACK = "0"
Start-Process -FilePath "bun" -ArgumentList @("run", "next", "dev", "-p", $Port, "--webpack") -NoNewWindow
Start-Sleep -Seconds 5

# =============================================================================
# STEP 5: Test API
# =============================================================================
Write-Host "[5/5] Testing kernel API..." -ForegroundColor Gray
try {
    $body = @{ task = "Check system health" } | ConvertTo-Json -Compress
    $resp = Invoke-RestMethod -Uri "http://localhost:$Port/api/kernel" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 10 -ErrorAction Stop
    Write-Host "  ✅ API Response:" -ForegroundColor Green
    Write-Host "     worker: $($resp.worker)" -ForegroundColor DarkGray
    Write-Host "     confidence: $($resp.confidence)" -ForegroundColor DarkGray
} catch {
    Write-Host "  ⚠️  API not ready yet — server may still be compiling" -ForegroundColor Yellow
}

Pop-Location
Write-Host "[OKIRU] Done. Check http://localhost:$Port" -ForegroundColor Green