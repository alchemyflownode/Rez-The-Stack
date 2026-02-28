# kernel-watchdog.ps1
# Permanent self-healing loop for Cognitive Kernel

param(
    [int]$IntervalSeconds = 300,  # 5 minutes default
    [switch]$DaemonMode = $false
)

$ErrorActionPreference = "Continue"
$logFile = "watchdog.log"
$pidFile = "watchdog.pid"
$maxAttempts = 3

# Logging function
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp [$Level] $Message" | Out-File -FilePath $logFile -Append
    Write-Host "$timestamp [$Level] $Message" -ForegroundColor @{
        "INFO" = "Cyan"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }[$Level]
}

# Test endpoint function
function Test-KernelEndpoint {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000/api/kernel" -Method GET -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            $content = $response.Content
            if ($content -and $content.Trim()) {
                try {
                    $json = $content | ConvertFrom-Json
                    if ($json.patterns) {
                        return @{ status = "healthy"; patterns = $json.patterns.Count }
                    } else {
                        return @{ status = "degraded"; reason = "No patterns field" }
                    }
                } catch {
                    return @{ status = "unhealthy"; reason = "Invalid JSON" }
                }
            } else {
                return @{ status = "unhealthy"; reason = "Empty response" }
            }
        } else {
            return @{ status = "unhealthy"; reason = "HTTP $($response.StatusCode)" }
        }
    } catch {
        return @{ status = "dead"; reason = $_.Exception.Message }
    }
}

# Self-healing function
function Start-Healing {
    param([string]$Reason)
    
    Write-Log "🩺 Healing triggered: $Reason" -Level "WARN"
    
    # Step 1: Check if server is running
    $proc = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*next*" }
    
    if (-not $proc) {
        Write-Log "Server not running. Attempting restart..." -Level "WARN"
        
        # Start server in new window
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
        $startCmd = "cd '$scriptPath'; `$env:NEXT_TURBOPACK=0; bun run next dev -p 3000 --webpack"
        Start-Process powershell -ArgumentList "-NoExit", "-Command", $startCmd
        
        Write-Log "Server restart initiated" -Level "INFO"
        Start-Sleep -Seconds 10
    }
    
    # Step 2: Test again
    $health = Test-KernelEndpoint
    
    if ($health.status -eq "healthy") {
        Write-Log "✅ Healing successful" -Level "SUCCESS"
        return $true
    }
    
    # Step 3: If still failing, feed to kernel for diagnosis
    if ($health.status -ne "healthy") {
        Write-Log "Feeding error to kernel for diagnosis..." -Level "INFO"
        
        $diagnosisTask = @{
            task = @"
The kernel API is returning: $($health.reason)
Please diagnose and suggest fix.
"@
            maxIterations = 2
        } | ConvertTo-Json
        
        try {
            $diagnosis = Invoke-RestMethod -Uri "http://localhost:3000/api/kernel" `
                -Method POST `
                -Body $diagnosisTask `
                -ContentType "application/json" `
                -TimeoutSec 30
            
            Write-Log "Kernel diagnosis: $($diagnosis.result.rootFound)" -Level "INFO"
            
            # If kernel suggests DB fix
            if ($diagnosis.result.rootFound -match "database|prisma|migration") {
                Write-Log "Running database fix..." -Level "INFO"
                & "bunx" "prisma" "db" "push" 2>&1 | Out-Null
            }
        } catch {
            Write-Log "Kernel diagnosis failed: $_" -Level "ERROR"
        }
    }
    
    return $false
}

# Main loop
function Start-Watchdog {
    Write-Log "🦊 Cognitive Kernel Watchdog Started" -Level "SUCCESS"
    Write-Log "Interval: $IntervalSeconds seconds" -Level "INFO"
    Write-Log "Daemon Mode: $DaemonMode" -Level "INFO"
    
    # Save PID
    $PID | Out-File -FilePath $pidFile
    
    $loopCount = 0
    
    while ($true) {
        $loopCount++
        Write-Log "Health check #$loopCount" -Level "INFO"
        
        $health = Test-KernelEndpoint
        
        switch ($health.status) {
            "healthy" {
                Write-Log "✅ Kernel healthy - $($health.patterns) patterns in memory" -Level "SUCCESS"
            }
            "degraded" {
                Write-Log "⚠️ Kernel degraded: $($health.reason)" -Level "WARN"
                Start-Healing -Reason $health.reason
            }
            "unhealthy" {
                Write-Log "❌ Kernel unhealthy: $($health.reason)" -Level "ERROR"
                Start-Healing -Reason $health.reason
            }
            "dead" {
                Write-Log "💀 Kernel dead: $($health.reason)" -Level "ERROR"
                Start-Healing -Reason "Server not responding"
            }
        }
        
        if (-not $DaemonMode) {
            Write-Log "Single check complete. Exiting." -Level "INFO"
            break
        }
        
        Write-Log "Sleeping $IntervalSeconds seconds..." -Level "INFO"
        Start-Sleep -Seconds $IntervalSeconds
    }
}

# Run
Start-Watchdog