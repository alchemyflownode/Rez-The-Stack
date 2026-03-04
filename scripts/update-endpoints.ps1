<#
.SYNOPSIS
    REZ HIVE - Endpoint & Import Auditor/Updater
    
.DESCRIPTION
    Scans all .ts/.tsx/.py files for:
    - API endpoint references (/api/*)
    - Import paths (@/workers, @/components, etc.)
    - Config value usage (OLLAMA_BASE_URL, etc.)
    
    Reports mismatches and optionally fixes them.
    
.USAGE
    .\scripts\update-endpoints.ps1 -WhatIf     # Show what would change
    .\scripts\update-endpoints.ps1 -Confirm    # Show + ask before each change
    .\scripts\update-endpoints.ps1 -Force      # Apply all changes automatically
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Force,      # Apply changes without prompting
    [switch]$WhatIf,     # Show what would change (default)
    [string]$ProjectRoot = "D:\okiru-os\The Reztack OS"
)

# ═══════════════════════════════════════════════════════════════
# CONFIGURATION (Match your backend/config.py)
# ═══════════════════════════════════════════════════════════════
$Config = @{
    # API Endpoints (Next.js app router)
    ApiPrefix = "/api"
    ApiRoutes = @{
        "/api/kernel"      = "POST"  # Brain worker proxy
        "/api/status"      = "GET"   # Health check
        "/api/memory"      = "GET"   # Vector memory (mock or ChromaDB)
        "/api/hands/execute" = "POST" # Command execution (mock or Python)
        "/api/workers/status" = "GET" # Worker health
        "/api/search"      = "POST"  # Web search (SearXNG fallback)
        "/api/config"      = "GET"   # Config dump (debug)
    }
    
    # Import path aliases (tsconfig.json paths)
    ImportAliases = @{
        "@/workers"        = "src/workers"
        "@/components"     = "src/components" 
        "@/lib"            = "src/lib"
        "@/config"         = "src/config"
        "@/backend"        = "backend"  # For shared types
    }
    
    # Environment variable references
    EnvVars = @{
        "OLLAMA_BASE_URL"  = "http://localhost:11434"
        "OLLAMA_MODEL"     = "sovereign-constitutional:latest"
        "API_URL"          = "http://localhost:8001"
        "SEARXNG_URL"      = "http://localhost:8080"
        "CHROMA_HOST"      = "localhost"
        "CHROMA_PORT"      = "8000"
    }
    
    # Python backend paths
    PythonFiles = @(
        "backend/kernel.py",
        "backend/api/*.py", 
        "backend/services/*.py",
        "backend/mcp/*.py"
    )
}

# ═══════════════════════════════════════════════════════════════
# MAIN EXECUTION
# ═══════════════════════════════════════════════════════════════
Write-Host "`n╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   REZ HIVE - ENDPOINT & IMPORT AUDIT v1.0         ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

$Results = @{
    FilesScanned = 0
    IssuesFound = @()
    ChangesMade = 0
}

# ───────────────────────────────────────────────────────────────
# 1. SCAN FRONTEND FILES (.ts/.tsx)
# ───────────────────────────────────────────────────────────────
Write-Host "[1/3] Scanning frontend files..." -ForegroundColor Yellow

$frontendFiles = Get-ChildItem -Path "$ProjectRoot/src" -Recurse -Include "*.ts","*.tsx" -ErrorAction SilentlyContinue

foreach ($file in $frontendFiles) {
    $Results.FilesScanned++
    $content = Get-Content $file.FullName -Raw
    $relativePath = $file.FullName.Replace("$ProjectRoot\", "")
    
    # Check for hardcoded API URLs (should use relative or env var)
    $hardcodedApis = [regex]::Matches($content, 'http://localhost:\d+/api/[^''"]*')
    foreach ($match in $hardcodedApis) {
        $Results.IssuesFound += @{
            File = $relativePath
            Line = ($content.Substring(0, $match.Index) -split "`n").Count
            Issue = "Hardcoded API URL: $($match.Value)"
            Fix = "Use relative path '/api/...' or process.env.API_URL"
            Type = "Frontend/API"
        }
    }
    
    # Check for incorrect import aliases
    foreach ($alias in $Config.ImportAliases.Keys) {
        $expected = $Config.ImportAliases[$alias]
        # Look for imports that don't match expected pattern
        if ($content -match "from\s+['`"]$alias[^/]") {
            # This is correct usage of alias
        } elseif ($content -match "from\s+['`"]\.\./\.\./src/workers") {
            $Results.IssuesFound += @{
                File = $relativePath
                Issue = "Relative import to workers, could use alias: $alias"
                Fix = "Replace with: import ... from '$alias/...'"
                Type = "Frontend/Import"
            }
        }
    }
    
    # Check for env var usage consistency
    foreach ($envVar in $Config.EnvVars.Keys) {
        # Check if env var is referenced but might be undefined
        if ($content -match "process\.env\.$envVar" -and $content -notmatch "$envVar\s*\?\?") {
            $Results.IssuesFound += @{
                File = $relativePath
                Issue = "Env var $envVar used without fallback"
                Fix = "Use: process.env.$envVar ?? '$($Config.EnvVars[$envVar])'"
                Type = "Frontend/Env"
            }
        }
    }
}

# ───────────────────────────────────────────────────────────────
# 2. SCAN PYTHON BACKEND FILES
# ───────────────────────────────────────────────────────────────
Write-Host "[2/3] Scanning Python backend files..." -ForegroundColor Yellow

$pythonFiles = Get-ChildItem -Path "$ProjectRoot/backend" -Recurse -Include "*.py" -ErrorAction SilentlyContinue

foreach ($file in $pythonFiles) {
    $Results.FilesScanned++
    $content = Get-Content $file.FullName -Raw
    $relativePath = $file.FullName.Replace("$ProjectRoot\", "")
    
    # Check for hardcoded URLs that should use config
    $hardcodedUrls = [regex]::Matches($content, 'http://localhost:\d+[^''"]*')
    foreach ($match in $hardcodedUrls) {
        $url = $match.Value
        # Check if this URL matches a config value
        $matched = $false
        foreach ($envVar in $Config.EnvVars.GetEnumerator()) {
            if ($url -eq $envVar.Value) {
                $matched = $true
                break
            }
        }
        if (-not $matched -and $url -notmatch "127.0.0.1") {
            $Results.IssuesFound += @{
                File = $relativePath
                Issue = "Hardcoded URL: $url"
                Fix = "Use os.getenv('VAR_NAME', 'default') instead"
                Type = "Backend/Config"
            }
        }
    }
    
    # Check for missing config imports
    if ($content -match "os\.getenv\(" -and $content -notmatch "from dotenv import") {
        $Results.IssuesFound += @{
            File = $relativePath
            Issue = "Uses os.getenv but missing 'from dotenv import load_dotenv'"
            Fix = "Add: from dotenv import load_dotenv; load_dotenv()"
            Type = "Backend/Import"
        }
    }
    
    # Check for API route consistency
    if ($relativePath -match "backend/api/.*\.py") {
        $routeName = [System.IO.Path]::GetFileNameWithoutExtension($relativePath)
        $expectedPath = "/api/$routeName"
        # Verify the FastAPI router prefix matches
        if ($content -match '@router\.(get|post|put|delete)\(["'']([^"'']+)') {
            $routePath = $matches[2]
            if ($routePath -notmatch "^$expectedPath") {
                $Results.IssuesFound += @{
                    File = $relativePath
                    Issue = "Route path '$routePath' doesn't match expected '$expectedPath'"
                    Fix = "Update @router decorator path to match file location"
                    Type = "Backend/Route"
                }
            }
        }
    }
}

# ───────────────────────────────────────────────────────────────
# 3. SCAN CONFIG & ENV FILES
# ───────────────────────────────────────────────────────────────
Write-Host "[3/3] Scanning config files..." -ForegroundColor Yellow

# Check .env.local exists and has required vars
$envFile = "$ProjectRoot/.env.local"
if (Test-Path $envFile) {
    $envContent = Get-Content $envFile -Raw
    foreach ($envVar in $Config.EnvVars.Keys) {
        if ($envContent -notmatch "^$envVar\s*=") {
            $Results.IssuesFound += @{
                File = ".env.local"
                Issue = "Missing env var: $envVar"
                Fix = "Add: $envVar=$($Config.EnvVars[$envVar])"
                Type = "Config/Missing"
            }
        }
    }
} else {
    $Results.IssuesFound += @{
        File = ".env.local"
        Issue = "File not found"
        Fix = "Create .env.local with template values"
        Type = "Config/Missing"
    }
}

# Check tsconfig.json has path aliases
$tsconfig = "$ProjectRoot/tsconfig.json"
if (Test-Path $tsconfig) {
    $tsContent = Get-Content $tsconfig -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($tsContent.compilerOptions.paths) {
        foreach ($alias in $Config.ImportAliases.Keys) {
            if ($tsContent.compilerOptions.paths.$alias -eq $null) {
                $Results.IssuesFound += @{
                    File = "tsconfig.json"
                    Issue = "Missing path alias: $alias"
                    Fix = "Add to compilerOptions.paths: `"$alias/*`": [`"$($Config.ImportAliases[$alias])/*`"]"
                    Type = "Config/Alias"
                }
            }
        }
    }
}

# ═══════════════════════════════════════════════════════════════
# REPORT RESULTS
# ═══════════════════════════════════════════════════════════════
Write-Host "`n╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                 AUDIT RESULTS                      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "Files scanned: $($Results.FilesScanned)" -ForegroundColor Cyan
Write-Host "Issues found:  $($Results.IssuesFound.Count)" -ForegroundColor $(if($Results.IssuesFound.Count -eq 0){"Green"}else{"Yellow"})

if ($Results.IssuesFound.Count -gt 0) {
    Write-Host "`nIssues by type:" -ForegroundColor Cyan
    $Results.IssuesFound | Group-Object Type | ForEach-Object {
        Write-Host "  $($_.Name): $($_.Count)" -ForegroundColor Gray
    }
    
    Write-Host "`nDetailed issues:" -ForegroundColor Cyan
    $Results.IssuesFound | ForEach-Object {
        Write-Host "`n  File: $($_.File)" -ForegroundColor Yellow
        Write-Host "  Type: $($_.Type)" -ForegroundColor Gray
        Write-Host "  Issue: $($_.Issue)" -ForegroundColor White
        Write-Host "  Fix:   $($_.Fix)" -ForegroundColor Green
    }
}

# ═══════════════════════════════════════════════════════════════
# APPLY FIXES (If requested)
# ═══════════════════════════════════════════════════════════════
if ($Force -or $Confirm) {
    Write-Host "`n[APPLYING FIXES]" -ForegroundColor Cyan
    
    foreach ($issue in $Results.IssuesFound) {
        $filePath = "$ProjectRoot\$($issue.File)"
        
        if (-not (Test-Path $filePath)) {
            Write-Host "  ⚠ Skip (file not found): $($issue.File)" -ForegroundColor Yellow
            continue
        }
        
        $content = Get-Content $filePath -Raw
        $newContent = $content
        
        # Apply fix based on type
        switch ($issue.Type) {
            "Frontend/API" {
                # Replace hardcoded localhost URLs with relative paths
                $newContent = $content -replace 'http://localhost:\d+(/api/[^''"]*)', '$1'
            }
            "Frontend/Env" {
                # Add fallback to env var usage
                foreach ($envVar in $Config.EnvVars.Keys) {
                    $default = $Config.EnvVars[$envVar]
                    $newContent = $newContent -replace "process\.env\.$envVar(?!\s*\?\?)", "process.env.$envVar ?? `"$default`""
                }
            }
            "Backend/Config" {
                # Replace hardcoded URLs with os.getenv
                foreach ($envVar in $Config.EnvVars.GetEnumerator()) {
                    $newContent = $newContent -replace [regex]::Escape($envVar.Value), "os.getenv('$($envVar.Name)', '$($envVar.Value)')"
                }
            }
            "Backend/Import" {
                # Add missing dotenv import
                if ($newContent -match "import os" -and $newContent -notmatch "from dotenv import") {
                    $newContent = $newContent -replace "(import os\r?\n)", "`$1from dotenv import load_dotenv`nload_dotenv()`n"
                }
            }
            default {
                Write-Host "  ⚠ No auto-fix for type: $($issue.Type)" -ForegroundColor Yellow
                continue
            }
        }
        
        if ($newContent -ne $content) {
            if ($PSCmdlet.ShouldProcess($filePath, "Apply fix: $($issue.Issue)")) {
                # Backup first
                Copy-Item $filePath "$filePath.bak" -ErrorAction SilentlyContinue
                # Write changes
                [System.IO.File]::WriteAllText($filePath, $newContent, [System.Text.Encoding]::UTF8)
                Write-Host "  ✓ Fixed: $($issue.File)" -ForegroundColor Green
                $Results.ChangesMade++
            }
        }
    }
    
    Write-Host "`n[SUMMARY]" -ForegroundColor Cyan
    Write-Host "Changes applied: $($Results.ChangesMade)" -ForegroundColor Green
    Write-Host "Backups created: *.bak files in modified directories" -ForegroundColor Gray
}

# ═══════════════════════════════════════════════════════════════
# EXPORT REPORT
# ═══════════════════════════════════════════════════════════════
$reportPath = "$ProjectRoot/reports/endpoint-audit-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$Results | ConvertTo-Json -Depth 10 | Out-File $reportPath -Encoding UTF8
Write-Host "`nReport exported: $reportPath" -ForegroundColor Gray

Write-Host "`n╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║              AUDIT COMPLETE                        ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan