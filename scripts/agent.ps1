<#
.SYNOPSIS
    Local Autonomous Agent - Bulletproof JSON Parser
#>

param(
    [string]$Model = "phi3:latest",
    [string]$Goal = ""
)

 $ApiUrl = "http://localhost:11434/api/generate"
 $MaxIterations = 10

# --- TOOL EXECUTORS ---
function Invoke-AgentTool {
    param($Decision)
    
    # Safety Check: Prevent dangerous commands
    $dangerousPatterns = @("Remove-Item", "del ", "Format-Volume", "rm ")
    if ($Decision.action -eq "powershell") {
        foreach ($pattern in $dangerousPatterns) {
            if ($Decision.command -match $pattern) {
                return "[BLOCKED] Constraint violation: Dangerous command detected."
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
                Set-Content -Path $Decision.filename -Value $Decision.content -Force
                return "File written successfully to $($Decision.filename)."
            }
            catch { return "[Error writing file]: $_" }
        }
        "read_file" {
            Write-Host "   📖 Reading: $($Decision.filename)" -ForegroundColor DarkGray
            try {
                if (Test-Path $Decision.filename) {
                    return Get-Content $Decision.filename -Raw
                } else { return "File not found." }
            }
            catch { return "[Error reading file]: $_" }
        }
        "finish" {
            Write-Host "`n✔ TASK COMPLETE" -ForegroundColor Green
            Write-Host "   Result: $($Decision.result)" -ForegroundColor White
            exit
        }
        Default { return "Unknown action: $($Decision.action)" }
    }
}

# --- MAIN LOOP ---

# Check Ollama
try { $null = Invoke-WebRequest -Uri "http://localhost:11434" -TimeoutSec 2 -UseBasicParsing } 
catch { Write-Host "Error: Ollama not running." -ForegroundColor Red; exit }

if (-not $Goal) { $Goal = Read-Host "Enter goal" }

 $Context = @(
    "SYSTEM: You are an autonomous agent. Output ONLY valid JSON. No markdown. No explanation."
    "GOAL: $Goal"
)

Clear-Host
Write-Host "🤖 AGENT ACTIVATED: $Goal`n" -ForegroundColor Cyan

for ($i = 0; $i -lt $MaxIterations; $i++) {
    
    # Construct Prompt
    $Prompt = $Context -join "`n"
    $Prompt += "`n`nOUTPUT JSON NOW:"

    $Body = @{ model = $Model; prompt = $Prompt; stream = $false } | ConvertTo-Json -Depth 5
    
    # Call LLM
    try {
        $Response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Body $Body -ContentType "application/json"
        $RawOutput = $Response.response.Trim()
    } catch {
        Write-Host "   [Error] Ollama call failed." -ForegroundColor Red
        continue
    }

    # --- BULLETPROOF PARSER ---
    $JsonObj = $null
    
    # 1. Try direct parse
    try { $JsonObj = $RawOutput | ConvertFrom-Json } 
    catch {}

    # 2. Extract from Markdown Code Block
    if (-not $JsonObj) {
        if ($RawOutput -match '```(?:json)?\s*([\s\S]*?)\s*```') {
            try { $JsonObj = $matches[1] | ConvertFrom-Json } catch {}
        }
    }

    # 3. Extract first {...} block (greedy match)
    if (-not $JsonObj) {
        if ($RawOutput -match '\{[\s\S]*\}') {
            try { $JsonObj = $matches[0] | ConvertFrom-Json } catch {}
        }
    }

    # Process Decision
    if ($JsonObj) {
        $Observation = Invoke-AgentTool $JsonObj
        
        # Update Context (Memory)
        $Context += "ASSISTANT: $RawOutput"
        $Context += "SYSTEM: Observation: $Observation"
    } else {
        Write-Host "   [Parser Failed] Raw output was:" -ForegroundColor Yellow
        Write-Host $RawOutput
        $Context += "SYSTEM: Your last output was not valid JSON. You MUST output ONLY a JSON object."
    }
}

Write-Host "`nMax iterations reached." -ForegroundColor Yellow