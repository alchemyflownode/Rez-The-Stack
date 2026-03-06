<#
.SYNOPSIS
    Local Autonomous Agent - TRULY Bulletproof
#>

param(
    [string]$Model = "phi3:latest",
    [string]$Goal = ""
)

 $ApiUrl = "http://localhost:11434/api/generate"
 $MaxIterations = 10

function Invoke-AgentTool {
    param($Decision)
    
    $dangerousPatterns = @("Remove-Item", "del ", "Format-Volume", "rm ", "rmdir")
    if ($Decision.action -eq "powershell") {
        foreach ($pattern in $dangerousPatterns) {
            if ($Decision.command -match $pattern) {
                return "[BLOCKED] Dangerous command detected."
            }
        }
    }

    switch ($Decision.action) {
        "powershell" {
            Write-Host "   ⚙️  Executing: $($Decision.command)" -ForegroundColor DarkGray
            try {
                $output = Invoke-Expression $Decision.command 2>&1 | Out-String
                if (-not $output.Trim()) { $output = "[Success: No output]" }
                return $output
            }
            catch { return "[Error]: $_" }
        }
        "write_file" {
            Write-Host "   📝 Writing: $($Decision.filename)" -ForegroundColor DarkGray
            try {
                # FIX: Use UTF8 encoding explicitly for older PowerShell
                [System.IO.File]::WriteAllText($Decision.filename, $Decision.content, [System.Text.Encoding]::UTF8)
                return "File written successfully to $($Decision.filename)."
            }
            catch { return "[Error]: $_" }
        }
        "read_file" {
            Write-Host "   📖 Reading: $($Decision.filename)" -ForegroundColor DarkGray
            try {
                if (Test-Path $Decision.filename) {
                    return [System.IO.File]::ReadAllText($Decision.filename)
                } else { return "File not found." }
            }
            catch { return "[Error]: $_" }
        }
        "finish" {
            Write-Host "`n✔ TASK COMPLETE" -ForegroundColor Green
            Write-Host "   Result: $($Decision.result)" -ForegroundColor White
            exit 0
        }
        Default { return "Unknown action: $($Decision.action)" }
    }
}

function Extract-Json {
    param($RawText)
    
    $JsonObj = $null
    $CleanText = $RawText.Trim()
    
    # Method 1: Strip ALL markdown first, then parse
    $CleanText = $CleanText -replace '(?s)```json\s*', ''
    $CleanText = $CleanText -replace '(?s)```\s*', ''
    
    # Method 2: Find JSON object with single-line mode (?s)
    if ($CleanText -match '(?s)\{.*\}') {
        $jsonCandidate = $matches[0]
        try {
            $JsonObj = $jsonCandidate | ConvertFrom-Json
            return $JsonObj
        } catch {
            # Try to fix common issues
            $jsonCandidate = $jsonCandidate -replace ',\s*}', '}'
            $jsonCandidate = $jsonCandidate -replace ',\s*]', ']'
            try {
                $JsonObj = $jsonCandidate | ConvertFrom-Json
                return $JsonObj
            } catch {}
        }
    }
    
    return $null
}

# Check Ollama
try { $null = Invoke-WebRequest -Uri "http://localhost:11434" -TimeoutSec 2 -UseBasicParsing } 
catch { Write-Host "Error: Ollama not running." -ForegroundColor Red; exit 1 }

if (-not $Goal) { $Goal = Read-Host "Enter goal" }

# CRITICAL: Keep context CLEAN - don't let model see its own failures
 $LastObservation = ""
 $IterationCount = 0

Clear-Host
Write-Host "🤖 AGENT ACTIVATED: $Goal`n" -ForegroundColor Cyan

for ($i = 0; $i -lt $MaxIterations; $i++) {
    $IterationCount++
    
    # Build FRESH prompt each time - NO history pollution
    $Prompt = @"
You are an autonomous agent. Your goal: $Goal

You have completed $IterationCount steps so far.
Last observation: $LastObservation

RULES:
1. Output ONLY valid JSON - no markdown, no explanation
2. Use actual values, not placeholders like "path"
3. Available actions:
   {"action": "write_file", "filename": "actual_filename.txt", "content": "actual content"}
   {"action": "read_file", "filename": "filename.txt"}
   {"action": "powershell", "command": "safe command"}
   {"action": "finish", "result": "summary"}

OUTPUT NOW (JSON only):
"@

    $Body = @{ model = $Model; prompt = $Prompt; stream = $false } | ConvertTo-Json -Depth 5
    
    try {
        $Response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Body $Body -ContentType "application/json"
        $RawOutput = $Response.response.Trim()
    } catch {
        Write-Host "   [Error] Ollama call failed." -ForegroundColor Red
        continue
    }
    
    Write-Host "   [Raw Output]" -ForegroundColor DarkGray
    Write-Host $RawOutput.Substring(0, [Math]::Min(200, $RawOutput.Length)) -ForegroundColor DarkGray
    
    $JsonObj = Extract-Json $RawOutput
    
    if ($JsonObj -and $JsonObj.action) {
        $LastObservation = Invoke-AgentTool $JsonObj
        Write-Host "   [Observation]: $LastObservation" -ForegroundColor Gray
    } else {
        $LastObservation = "Invalid JSON output. You MUST output only a JSON object with an 'action' field."
        Write-Host "   [Parser Failed]" -ForegroundColor Yellow
    }
}

Write-Host "`n⚠ Max iterations reached." -ForegroundColor Yellow