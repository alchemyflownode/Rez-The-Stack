<#
.SYNOPSIS
    Local Autonomous Agent (ReAct Loop) - WORKING VERSION
    Uses /api/generate endpoint with proper JSON parsing
#>

param(
    [string]$Model = "phi3:latest",
    [string]$Goal = ""
)

$ApiUrl = "http://localhost:11434/api/generate"
$MaxIterations = 10

# --- 1. TOOL EXECUTORS ---
function Invoke-AgentTool {
    param($Decision)
    
    switch ($Decision.action) {
        "powershell" {
            Write-Host "   [Executing Command]: $($Decision.command)" -ForegroundColor DarkGray
            try {
                $output = Invoke-Expression $Decision.command 2>&1 | Out-String
                if (-not $output.Trim()) { $output = "[Command executed successfully, no output]" }
                return $output
            }
            catch { return "[Error]: $_" }
        }
        "write_file" {
            Write-Host "   [Writing File]: $($Decision.filename)" -ForegroundColor DarkGray
            try {
                Set-Content -Path $Decision.filename -Value $Decision.content -Force
                return "File written successfully."
            }
            catch { return "[Error writing file]: $_" }
        }
        "read_file" {
            Write-Host "   [Reading File]: $($Decision.filename)" -ForegroundColor DarkGray
            try {
                if (Test-Path $Decision.filename) {
                    return Get-Content $Decision.filename -Raw
                } else { return "File not found." }
            }
            catch { return "[Error reading file]: $_" }
        }
        "finish" {
            Write-Host "`nâœ” TASK COMPLETE" -ForegroundColor Green
            Write-Host $Decision.result
            exit
        }
        Default {
            return "Unknown action."
        }
    }
}

# --- 2. CHECK OLLAMA ---
try { 
    $null = Invoke-WebRequest -Uri "http://localhost:11434" -TimeoutSec 2 -UseBasicParsing 
} catch { 
    Write-Host "Error: Ollama not running. Start 'ollama serve'." -ForegroundColor Red
    exit 
}

if (-not $Goal) { $Goal = Read-Host "Enter goal for the agent" }

# Initialize conversation history
$Messages = @()
$Messages += "System: You are an autonomous AI agent. You have access to tools. Respond with JSON only."
$Messages += "User: $Goal"

Clear-Host
Write-Host "ðŸ¤– AGENT ACTIVATED: $Goal`n" -ForegroundColor Cyan

for ($i = 0; $i -lt $MaxIterations; $i++) {
    
    # Build prompt from conversation history
    $Prompt = $Messages -join "`n"
    $Prompt += @"

`n`nRespond with JSON only. Available actions:
- {"action": "powershell", "command": "command"}
- {"action": "write_file", "filename": "path", "content": "text"}
- {"action": "read_file", "filename": "path"}
- {"action": "finish", "result": "summary"}

Your JSON response:
"@

    # Call Ollama
    $Body = @{
        model = $Model
        prompt = $Prompt
        stream = $false
    } | ConvertTo-Json

    Write-Host "   [Calling Ollama...]" -ForegroundColor DarkGray
    $Response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Body $Body -ContentType "application/json"
    $AiReply = $Response.response.Trim()

    Write-Host "   [DEBUG] Raw response: $AiReply" -ForegroundColor Magenta

    # Parse Decision - FIXED PARSER
    try {
        # Clean up the response - remove markdown code blocks
        $cleanReply = $AiReply
        
        # Remove markdown code blocks if present
        if ($cleanReply -match '```json\s*(.*?)\s*```') {
            $cleanReply = $matches[1]
        }
        elseif ($cleanReply -match '```\s*(.*?)\s*```') {
            $cleanReply = $matches[1]
        }
        
        $cleanReply = $cleanReply.Trim()
        Write-Host "   [DEBUG] Cleaned response: $cleanReply" -ForegroundColor Cyan
        
        # Try to parse as JSON
        $JsonRaw = $cleanReply | ConvertFrom-Json
        Write-Host "   [DEBUG] Successfully parsed JSON!" -ForegroundColor Green
    }
    catch {
        Write-Host "   [Error]: Could not parse JSON. Raw: $AiReply" -ForegroundColor Red
        $Messages += "Assistant: $AiReply"
        $Messages += "User: Invalid JSON. Please respond with valid JSON only, without markdown."
        continue
    }

    # Execute Tool
    $Observation = Invoke-AgentTool $JsonRaw
    
    # Update conversation
    $Messages += "Assistant: $AiReply"
    $Messages += "User: Observation: $Observation"
    
    # Keep only last 10 messages to avoid context overflow
    if ($Messages.Count -gt 10) {
        $Messages = $Messages[-10..-1]
    }
}

Write-Host "`nMax iterations reached." -ForegroundColor Yellow
