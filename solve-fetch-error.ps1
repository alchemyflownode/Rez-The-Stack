# solve-fetch-error.ps1
# Self-healing loop for the frontend JSON error

$ErrorActionPreference = "Continue"
$maxAttempts = 5
$attempt = 1
$solved = $false

Write-Host "🦊 Starting self-healing loop for frontend fetch error..." -ForegroundColor Cyan

while (-not $solved -and $attempt -le $maxAttempts) {
    Write-Host "`n🔁 Attempt $attempt of $maxAttempts" -ForegroundColor Yellow

    # 1. Test the current state
    Write-Host "📡 Testing /api/kernel endpoint..." -ForegroundColor Gray
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000/api/kernel" -Method GET -TimeoutSec 5
        $content = $response.Content
        
        if ($response.StatusCode -eq 200 -and $content) {
            Write-Host "✅ Endpoint responded with status 200" -ForegroundColor Green
            
            # Try to parse JSON
            try {
                $json = $content | ConvertFrom-Json
                if ($json.patterns) {
                    Write-Host "✅ Valid JSON with $($json.patterns.Count) patterns" -ForegroundColor Green
                    $solved = $true
                    break
                } else {
                    Write-Host "⚠️ JSON received but no patterns field" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "❌ Invalid JSON received" -ForegroundColor Red
                Write-Host "Raw response (first 200 chars):" -ForegroundColor Gray
                Write-Host $content.Substring(0, [Math]::Min(200, $content.Length))
            }
        } else {
            Write-Host "❌ Bad response: $($response.StatusCode)" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Connection failed: $_" -ForegroundColor Red
    }

    if (-not $solved) {
        # 2. Feed the error into the kernel for diagnosis
        Write-Host "🧠 Feeding error to kernel for diagnosis..." -ForegroundColor Magenta
        
        $diagnosisTask = @{
            task = @"
The frontend is failing with:
'Failed to execute 'json' on 'Response': Unexpected end of JSON input'

Current fetchPatterns function has been updated, but error persists.
Diagnose why the API might be returning empty or malformed JSON.

Check:
1. Is the database connecting?
2. Are patterns being saved?
3. Is the GET handler returning properly?
4. Any uncaught exceptions?

Provide root cause and fix.
"@
            maxIterations = 3
        } | ConvertTo-Json

        try {
            $diagnosis = Invoke-RestMethod -Uri "http://localhost:3000/api/kernel" `
                -Method POST `
                -Body $diagnosisTask `
                -ContentType "application/json" `
                -TimeoutSec 30
            
            Write-Host "📋 Kernel diagnosis:" -ForegroundColor Cyan
            Write-Host $diagnosis.result.rootFound -ForegroundColor White
            
            # 3. If kernel suggests a fix, try to apply it
            if ($diagnosis.result.rootFound -match "fix.*database|prisma|migration") {
                Write-Host "🔧 Applying database fix..." -ForegroundColor Yellow
                # Add prisma push or regenerate
                & "bunx" "prisma" "db" "push" 2>&1 | Out-Null
            }
            
            if ($diagnosis.result.rootFound -match "restart|server") {
                Write-Host "🔧 Restarting server recommended" -ForegroundColor Yellow
                # You'd need to run this manually or wire up a restart
            }
        } catch {
            Write-Host "⚠️ Kernel diagnosis failed: $_" -ForegroundColor DarkYellow
        }

        # 4. Wait before next attempt
        Write-Host "⏳ Waiting 3 seconds before next attempt..." -ForegroundColor Gray
        Start-Sleep -Seconds 3
    }
    
    $attempt++
}

if ($solved) {
    Write-Host "`n🎉 SOLVED! Kernel API is responding correctly." -ForegroundColor Green
    Write-Host "Patterns available: $($json.patterns.Count)" -ForegroundColor Green
    
    # 5. Optional: Show patterns
    if ($json.patterns.Count -gt 0) {
        Write-Host "`n📚 Pattern Memory:" -ForegroundColor Cyan
        $json.patterns | ForEach-Object {
            Write-Host "  • $($_.name) (confidence: $($_.confidence))" -ForegroundColor White
        }
    }
} else {
    Write-Host "`n⚠️ Max attempts reached. Manual intervention needed." -ForegroundColor Red
    Write-Host "Check:" -ForegroundColor Yellow
    Write-Host "  • Is Ollama running? (ollama serve)" -ForegroundColor Yellow
    Write-Host "  • Is Next.js server running? (bun run dev)" -ForegroundColor Yellow
    Write-Host "  • Check database connection: bunx prisma studio" -ForegroundColor Yellow
}