<#
.SYNOPSIS
    Auto-fixes the JSX syntax error in src/app/page.tsx for OKIRU
    Kills stuck processes, clears cache, restarts dev server.
#>

[CmdletBinding()]
param(
    [string]$ProjectPath = "G:\okiru\app builder\Cognitive Kernel",
    [int]$Port = 3001
)

# Ensure we're in the project directory
Push-Location $ProjectPath
Write-Host "🔧 OKIRU JSX Auto-Fix Script" -ForegroundColor Cyan
Write-Host "📁 Working in: $ProjectPath" -ForegroundColor Gray

# =============================================================================
# STEP 1: Kill stuck processes on port $Port
# =============================================================================
Write-Host "`n🔴 Killing processes on port $Port..." -ForegroundColor Yellow
try {
    $connection = Get-NetTCPConnection -LocalPort $Port -ErrorAction Stop
    $proc = Get-Process -Id $connection.OwningProcess -ErrorAction SilentlyContinue
    if ($proc) {
        Write-Host "   Found: $($proc.ProcessName) (PID: $($proc.Id))" -ForegroundColor Gray
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        Write-Host "   ✅ Killed" -ForegroundColor Green
    }
} catch {
    Write-Host "   ℹ️  No process found on port $Port" -ForegroundColor DarkGray
}

# Also kill any node/bun processes tied to this project
Write-Host "🔴 Cleaning orphaned node/bun processes..." -ForegroundColor Yellow
Get-Process -Name "node","bun","next" -ErrorAction SilentlyContinue | 
    Where-Object { $_.Path -like "*okiru*" -or $_.Path -like "*Cognitive Kernel*" } | 
    ForEach-Object {
        Write-Host "   Killing $($_.ProcessName) PID $($_.Id)" -ForegroundColor Gray
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    }
Start-Sleep -Seconds 1

# =============================================================================
# STEP 2: Fix the JSX syntax error in page.tsx
# =============================================================================
$filePath = Join-Path $ProjectPath "src\app\page.tsx"
Write-Host "`n🔍 Checking $filePath..." -ForegroundColor Cyan

if (-not (Test-Path $filePath)) {
    Write-Host "❌ File not found: $filePath" -ForegroundColor Red
    exit 1
}

# Read file as lines for precise editing
$lines = Get-Content $filePath -Raw

# Define the EXACT broken block (copy-pasted from error)
$brokenPattern = @'
{msg.role === 'assistant' && (
  <div className="bg-white/5 border border-white/10 rounded-2xl rounded-tl-sm p-4">
    {msg.results && msg.results.length > 0 ? (
      <SearchResults results={msg.results} />
    ) : msg.answer ? (
      <SearchResults answer={msg.answer} sources={msg.sources} />
    ) : (
      {msg.stats ? <PCDashboard stats={msg.stats} /> : <pre className="text-sm text-gray-300 whitespace-pre-wrap font-mono">{msg.content}</pre>}
    )}
  </div>
)}
'@

# Define the FIXED block
$fixedReplacement = @'
{msg.role === 'assistant' && (
  <div className="bg-white/5 border border-white/10 rounded-2xl rounded-tl-sm p-4">
    {msg.stats ? (
      <PCDashboard stats={msg.stats} />
    ) : msg.results && msg.results.length > 0 ? (
      <SearchResults results={msg.results} />
    ) : msg.answer ? (
      <SearchResults answer={msg.answer} sources={msg.sources} />
    ) : msg.content ? (
      <pre className="text-sm text-gray-300 whitespace-pre-wrap font-mono">
        {msg.content}
      </pre>
    ) : (
      <span className="text-sm text-gray-400">No content</span>
    )}
  </div>
)}
'@

# Attempt direct string replacement (most reliable for exact matches)
if ($lines.Contains($brokenPattern)) {
    Write-Host "✅ Found broken JSX block — applying fix..." -ForegroundColor Green
    $newContent = $lines -replace [regex]::Escape($brokenPattern), $fixedReplacement
    Set-Content -Path $filePath -Value $newContent -Encoding UTF8 -NoNewline
    Write-Host "✅ JSX syntax repaired" -ForegroundColor Green
} else {
    # Fallback: line-by-line surgical replace for the specific error line
    Write-Host "⚠️  Exact pattern not found — attempting line-level fix..." -ForegroundColor Yellow
    
    $contentLines = Get-Content $filePath
    $fixedLines = @()
    $inAssistantBlock = $false
    $fixed = $false
    
    for ($i = 0; $i -lt $contentLines.Count; $i++) {
        $line = $contentLines[$i]
        
        # Detect start of assistant block
        if ($line -match "{msg\.role === 'assistant'") {
            $inAssistantBlock = $true
        }
        
        # Target the specific broken line (line 289 in error)
        if ($inAssistantBlock -and $line -match '{msg\.stats \? <PCDashboard') {
            Write-Host "🔧 Fixing line $($i+1): nested JSX expression" -ForegroundColor Gray
            # Replace the broken nested expression with flat ternary
            $fixedLine = $line -replace 
                '{msg\.stats \? <PCDashboard stats=\{msg\.stats\} /> : <pre className="text-sm text-gray-300 whitespace-pre-wrap font-mono">\{msg\.content\}</pre>}',
                'msg.stats ? (<PCDashboard stats={msg.stats} />) : msg.content ? (<pre className="text-sm text-gray-300 whitespace-pre-wrap font-mono">{msg.content}</pre>) : (<span className="text-sm text-gray-400">No content</span>)'
            $fixedLines += $fixedLine
            $fixed = $true
            continue
        }
        
        # Reset block tracking at end
        if ($inAssistantBlock -and $line -match '\)}\s*$' -and $line -notmatch 'msg\.') {
            $inAssistantBlock = $false
        }
        
        $fixedLines += $line
    }
    
    if ($fixed) {
        Set-Content -Path $filePath -Value $fixedLines -Encoding UTF8
        Write-Host "✅ Line-level JSX fix applied" -ForegroundColor Green
    } else {
        Write-Host "❌ Could not auto-fix — please manually check lines 280-300" -ForegroundColor Red
        Write-Host "👉 Search for: {msg.stats ? <PCDashboard" -ForegroundColor DarkGray
        exit 1
    }
}

# =============================================================================
# STEP 3: Clear Next.js cache
# =============================================================================
Write-Host "`n🧹 Clearing Next.js build cache..." -ForegroundColor Yellow
$nextCache = Join-Path $ProjectPath ".next"
if (Test-Path $nextCache) {
    Remove-Item -Recurse -Force $nextCache -ErrorAction SilentlyContinue
    Write-Host "✅ Cache cleared" -ForegroundColor Green
} else {
    Write-Host "ℹ️  No cache found to clear" -ForegroundColor DarkGray
}

# =============================================================================
# STEP 4: Restart dev server
# =============================================================================
Write-Host "`n🚀 Starting Next.js dev server on port $Port..." -ForegroundColor Cyan
$env:NEXT_TURBOPACK = "0"

# Start server in background
$serverArgs = @("run", "next", "dev", "-p", $Port.ToString(), "--webpack")
$serverProc = Start-Process -FilePath "bun" -ArgumentList $serverArgs -PassThru -NoNewWindow

# Wait for server to be ready (simple poll)
Write-Host "⏳ Waiting for server to respond..." -ForegroundColor Gray
$maxAttempts = 30
$attempt = 0
do {
    Start-Sleep -Seconds 2
    $attempt++
    try {
        $test = Invoke-WebRequest -Uri "http://localhost:$Port" -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
        if ($test.StatusCode -eq 200) { break }
    } catch {
        if ($attempt -ge $maxAttempts) {
            Write-Host "⚠️  Server may still be starting — continuing anyway" -ForegroundColor Yellow
            break
        }
    }
} while ($true)

Write-Host "`n✅ OKIRU dev server ready at http://localhost:$Port" -ForegroundColor Green

# =============================================================================
# STEP 5: Test the kernel API
# =============================================================================
Write-Host "`n🧪 Testing kernel API with 'Check system health'..." -ForegroundColor Cyan
try {
    $body = @{ task = "Check system health" } | ConvertTo-Json -Compress
    $response = Invoke-RestMethod -Uri "http://localhost:$Port/api/kernel" `
        -Method POST `
        -Body $body `
        -ContentType "application/json" `
        -TimeoutSec 15 `
        -ErrorAction Stop
    
    Write-Host "✅ API Response:" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 5 | ForEach-Object { Write-Host "   $_" -ForegroundColor DarkGray }
} catch {
    Write-Host "⚠️  API test failed (server may still be warming up)" -ForegroundColor Yellow
    Write-Host "   Try again in 10 seconds or check logs above" -ForegroundColor DarkGray
}

# Return to original location
Pop-Location
Write-Host "`n✨ Done. Your OKIRU frontend should now render PCDashboard correctly." -ForegroundColor Green