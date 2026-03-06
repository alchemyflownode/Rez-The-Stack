#!/usr/bin/env pwsh
# ===================================================
# 🏛️ REZ HIVE - UNIFIED SOVEREIGN AUDIT
# Combines inventory + validation + health checking
# ===================================================

param(
    [switch]$Detailed,
    [switch]$ExportJson,
    [switch]$ExportText,
    [switch]$FixIssues,
    [switch]$MetricsOnly,  # Just code metrics
    [switch]$HealthOnly    # Just health check
)

$ErrorActionPreference = "Continue"

# ===================================================
# UNIFIED AUDIT RESULTS
# ===================================================

$auditResults = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    ProjectRoot = (Get-Location).Path
    Status = "PASS"
    
    # From Script 2
    Categories = @{
        System = @{}
        Commands = @{}
        Folders = @{}
        Files = @{}
        Python = @{}
        Node = @{}
        Ollama = @{}
        Services = @{}
        Config = @{}
        DiskUsage = @{}
    }
    Issues = @()
    Warnings = @()
    Suggestions = @()
    
    # From Script 1
    Metrics = @{
        TotalFiles = 0
        TotalSize = 0
        PythonFiles = @()
        TypeScriptFiles = @()
        CodeLines = @{
            Python = 0
            TypeScript = 0
            Total = 0
        }
    }
    
    # NEW: Genesis verification
    Genesis = @{
        LedgerExists = $false
        LedgerValid = $false
        GenesisHash = $null
        DriftEvents = 0
    }
}

# ===================================================
# HELPER FUNCTIONS
# ===================================================

function Write-AuditHeader {
    param([string]$Text)
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  $Text" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
}

function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Get-FileSize {
    param([string]$Path)
    if (Test-Path $Path) {
        return (Get-Item $Path).Length
    }
    return -1
}

function Add-Issue {
    param(
        [string]$Category,
        [string]$Message,
        [string]$Severity = "ERROR"
    )
    
    $issue = @{
        Category = $Category
        Message = $Message
        Severity = $Severity
        Timestamp = Get-Date
    }
    
    switch ($Severity) {
        "ERROR" {
            $auditResults.Issues += $issue
            $auditResults.Status = "FAIL"
            Write-Host "  ❌ $Message" -ForegroundColor Red
        }
        "WARNING" {
            $auditResults.Warnings += $issue
            Write-Host "  ⚠️  $Message" -ForegroundColor Yellow
        }
        "INFO" {
            $auditResults.Suggestions += $issue
            Write-Host "  💡 $Message" -ForegroundColor Cyan
        }
    }
}

function Test-Port {
    param([int]$Port)
    try {
        $connection = New-Object System.Net.Sockets.TcpClient
        $connection.Connect("localhost", $Port)
        $connection.Close()
        return $true
    } catch {
        return $false
    }
}

function Get-CodeMetrics {
    param(
        [string]$Path,
        [string]$Filter
    )
    
    $files = Get-ChildItem -Path $Path -Recurse -Filter $Filter -ErrorAction SilentlyContinue
    $details = @()
    $totalLines = 0
    
    foreach ($file in $files) {
        $lines = (Get-Content $file.FullName -ErrorAction SilentlyContinue | Measure-Object -Line).Lines
        $totalLines += $lines
        
        $details += [PSCustomObject]@{
            File = $file.Name
            Path = $file.FullName.Replace((Get-Location).Path, "").TrimStart("\")
            Lines = $lines
            SizeKB = [math]::Round($file.Length / 1KB, 2)
            Modified = $file.LastWriteTime
        }
    }
    
    return @{
        Files = $details
        TotalLines = $totalLines
        FileCount = $files.Count
    }
}

# ===================================================
# MAIN AUDIT HEADER
# ===================================================

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  🏛️  REZ HIVE - UNIFIED SOVEREIGN AUDIT                     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "Started: $($auditResults.Timestamp)" -ForegroundColor White
Write-Host ""

# ===================================================
# 1. SYSTEM PREREQUISITES (from Script 2)
# ===================================================

if (!$MetricsOnly) {
    Write-AuditHeader "🖥️  SYSTEM PREREQUISITES"

    $systemAudit = @{
        OS = $PSVersionTable.OS
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        Hostname = hostname
        RAM = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
        CPUCores = (Get-CimInstance Win32_Processor).NumberOfCores
        DiskFree = [math]::Round((Get-PSDrive C).Free / 1GB, 2)
    }

    Write-Host "  Hostname: $($systemAudit.Hostname)" -ForegroundColor Gray
    Write-Host "  OS: $($systemAudit.OS)" -ForegroundColor Gray
    Write-Host "  PowerShell: v$($systemAudit.PowerShellVersion)" -ForegroundColor Gray
    Write-Host "  RAM: $($systemAudit.RAM) GB" -ForegroundColor Gray
    Write-Host "  CPU Cores: $($systemAudit.CPUCores)" -ForegroundColor Gray
    Write-Host "  Disk Free: $($systemAudit.DiskFree) GB" -ForegroundColor Gray

    if ($systemAudit.RAM -lt 8) {
        Add-Issue "System" "Low RAM: $($systemAudit.RAM)GB (recommended: 16GB+)" "WARNING"
    }
    if ($systemAudit.DiskFree -lt 20) {
        Add-Issue "System" "Low disk space: $($systemAudit.DiskFree)GB (need 20GB+ for models)" "WARNING"
    }

    $auditResults.Categories.System = $systemAudit
}

# ===================================================
# 2. REQUIRED COMMANDS (from Script 2)
# ===================================================

if (!$MetricsOnly) {
    Write-AuditHeader "⚙️  REQUIRED COMMANDS"

    $commands = @{
        "python" = @{
            Required = $true
            VersionCommand = "python --version"
            MinVersion = "3.10"
        }
        "pip" = @{
            Required = $true
            VersionCommand = "pip --version"
        }
        "node" = @{
            Required = $true
            VersionCommand = "node --version"
            MinVersion = "18.0"
        }
        "npm" = @{
            Required = $true
            VersionCommand = "npm --version"
        }
        "ollama" = @{
            Required = $true
            VersionCommand = "ollama --version"
        }
        "git" = @{
            Required = $false
            VersionCommand = "git --version"
        }
    }

    $commandResults = @{}

    foreach ($cmd in $commands.Keys) {
        $info = $commands[$cmd]
        
        if (Test-Command $cmd) {
            try {
                $version = Invoke-Expression $info.VersionCommand 2>&1 | Out-String
                $version = $version.Trim()
                
                Write-Host "  ✅ $cmd : $version" -ForegroundColor Green
                
                $commandResults[$cmd] = @{
                    Installed = $true
                    Version = $version
                }
                
                if ($info.MinVersion) {
                    $installedVer = $version -replace '[^0-9.]', ''
                    if ($installedVer -match '(\d+\.\d+)') {
                        $verNum = [version]$Matches[1]
                        $minNum = [version]$info.MinVersion
                        
                        if ($verNum -lt $minNum) {
                            Add-Issue "Commands" "$cmd version $installedVer below minimum $($info.MinVersion)" "WARNING"
                        }
                    }
                }
                
            } catch {
                Write-Host "  ⚠️  $cmd : Installed but version check failed" -ForegroundColor Yellow
                $commandResults[$cmd] = @{
                    Installed = $true
                    Version = "Unknown"
                }
            }
        } else {
            $severity = if ($info.Required) { "ERROR" } else { "WARNING" }
            Add-Issue "Commands" "$cmd not found" $severity
            
            $commandResults[$cmd] = @{
                Installed = $false
                Version = $null
            }
        }
    }

    $auditResults.Categories.Commands = $commandResults
}

# ===================================================
# 3. CODE METRICS (from Script 1) - FIXED FORMATTING
# ===================================================

if (!$HealthOnly) {
    Write-AuditHeader "📊 CODE METRICS & FILE INVENTORY"

    # Python files
    Write-Host "`n  🐍 Python Files:" -ForegroundColor Yellow
    $pythonMetrics = Get-CodeMetrics -Path "backend" -Filter "*.py"
    $auditResults.Metrics.PythonFiles = $pythonMetrics.Files
    $auditResults.Metrics.CodeLines.Python = $pythonMetrics.TotalLines
    
    Write-Host "     Files: $($pythonMetrics.FileCount)" -ForegroundColor Cyan
    Write-Host "     Lines: $($pythonMetrics.TotalLines)" -ForegroundColor Cyan
    
    if ($Detailed -and $pythonMetrics.Files) {
        $pythonMetrics.Files | Format-Table File, Lines, SizeKB -AutoSize
    }

    # TypeScript/TSX files
    Write-Host "`n  ⚛️  TypeScript/TSX Files:" -ForegroundColor Yellow
    $tsxMetrics = Get-CodeMetrics -Path "src" -Filter "*.tsx"
    $tsMetrics = Get-CodeMetrics -Path "src" -Filter "*.ts"
    
    $allTsFiles = @($tsxMetrics.Files) + @($tsMetrics.Files)
    $totalTsLines = $tsxMetrics.TotalLines + $tsMetrics.TotalLines
    
    $auditResults.Metrics.TypeScriptFiles = $allTsFiles
    $auditResults.Metrics.CodeLines.TypeScript = $totalTsLines
    $auditResults.Metrics.CodeLines.Total = $pythonMetrics.TotalLines + $totalTsLines
    
    Write-Host "     Files: $($allTsFiles.Count)" -ForegroundColor Cyan
    Write-Host "     Lines: $($totalTsLines)" -ForegroundColor Cyan
    
    if ($Detailed -and $allTsFiles) {
        $allTsFiles | Format-Table File, Lines, SizeKB -AutoSize
    }

    # Total project size
    Write-Host "`n  💾 Project Size:" -ForegroundColor Yellow
    $allFiles = Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue
    $totalSize = ($allFiles | Measure-Object -Property Length -Sum).Sum
    $auditResults.Metrics.TotalFiles = $allFiles.Count
    $auditResults.Metrics.TotalSize = $totalSize
    
    $totalSizeMB = [math]::Round($totalSize / 1MB, 2)
    Write-Host "     Total Files: $($allFiles.Count)" -ForegroundColor Cyan
    Write-Host "     Total Size: $totalSizeMB MB" -ForegroundColor Cyan
    Write-Host "     Total Code Lines: $($auditResults.Metrics.CodeLines.Total)" -ForegroundColor Cyan
}

# ===================================================
# 4. GENESIS LEDGER VERIFICATION (from Script 1)
# ===================================================

if (!$HealthOnly) {
    Write-AuditHeader "📜 GENESIS LEDGER VERIFICATION"

    $ledgerPath = "logs\state_ledger.json"
    if (Test-Path $ledgerPath) {
        try {
            $ledgerContent = Get-Content $ledgerPath -Raw | ConvertFrom-Json
            $ledgerSize = (Get-Item $ledgerPath).Length / 1KB
            
            $auditResults.Genesis.LedgerExists = $true
            $auditResults.Genesis.LedgerValid = $true
            $auditResults.Genesis.GenesisHash = $ledgerContent.genesis_block.hash
            $auditResults.Genesis.DriftEvents = $ledgerContent.genesis_block.drift_events
            
            Write-Host "  ✅ Ledger: state_ledger.json ($([math]::Round($ledgerSize, 2)) KB)" -ForegroundColor Green
            Write-Host "  📊 Genesis Time: $($ledgerContent.genesis_block.timestamp)" -ForegroundColor Cyan
            Write-Host "  📊 Version: $($ledgerContent.genesis_block.version)" -ForegroundColor Cyan
            Write-Host "  📊 Drift Events: $($ledgerContent.genesis_block.drift_events)" -ForegroundColor Cyan
            Write-Host "  🔒 Hash: $($ledgerContent.genesis_block.hash)" -ForegroundColor Gray
            
        } catch {
            Add-Issue "Genesis" "Ledger exists but is invalid/corrupted" "ERROR"
            $auditResults.Genesis.LedgerExists = $true
            $auditResults.Genesis.LedgerValid = $false
        }
    } else {
        Add-Issue "Genesis" "Ledger not found - Run genesis generation!" "WARNING"
        $auditResults.Genesis.LedgerExists = $false
    }
}

# ===================================================
# 5. SERVICE HEALTH (from Script 2)
# ===================================================

if (!$MetricsOnly) {
    Write-AuditHeader "🔌 RUNNING SERVICES"

    $services = @{
        "ChromaDB" = 8000
        "Kernel" = 8001
        "Frontend" = 3001
        "Ollama" = 11434
    }

    $serviceResults = @{}

    foreach ($service in $services.Keys) {
        $port = $services[$service]
        $running = Test-Port $port
        
        if ($running) {
            Write-Host "  ✅ $service running on port $port" -ForegroundColor Green
            $serviceResults[$service] = $true
        } else {
            Write-Host "  ⚠️  $service not running on port $port" -ForegroundColor Yellow
            $serviceResults[$service] = $false
        }
    }

    $auditResults.Categories.Services = $serviceResults
}

# ===================================================
# 6. CONFIGURATION VALIDATION (from Script 2)
# ===================================================

if (!$MetricsOnly) {
    Write-AuditHeader "⚙️  CONFIGURATION FILES"

    $configFiles = @(
        "package.json",
        "next.config.js",
        "tailwind.config.ts",
        "postcss.config.mjs",
        "backend/requirements.txt",
        "backend/.env",
        ".gitignore",
        "README.md"
    )

    foreach ($file in $configFiles) {
        if (Test-Path $file) {
            $size = (Get-Item $file).Length / 1KB
            Write-Host "  ✅ $file ($([math]::Round($size, 2)) KB)" -ForegroundColor Green
        } else {
            $optional = $file -in @("backend/.env")
            if ($optional) {
                Write-Host "  ⚠️  $file (optional, missing)" -ForegroundColor Yellow
            } else {
                Add-Issue "Config" "Missing: $file" "WARNING"
            }
        }
    }

    # Check .env
    if (Test-Path "backend/.env") {
        $envContent = Get-Content "backend/.env" -Raw
        
        if ($envContent -match "your-super-secret-key-change-this") {
            Add-Issue "Config" "JWT_SECRET using default value (SECURITY RISK!)" "ERROR"
        }
    }
}

# ===================================================
# FINAL SUMMARY - FIXED FORMATTING
# ===================================================

Write-Host "`n`n" 
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "                   UNIFIED AUDIT SUMMARY" -ForegroundColor White
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Magenta

Write-Host "`n  Status: " -NoNewline -ForegroundColor White
if ($auditResults.Status -eq "PASS") {
    Write-Host "✅ PASS" -ForegroundColor Green
} else {
    Write-Host "❌ FAIL" -ForegroundColor Red
}

$totalSizeMB = [math]::Round($auditResults.Metrics.TotalSize / 1MB, 2)
Write-Host "`n  📊 CODE METRICS:" -ForegroundColor White
Write-Host "     Total Files: $($auditResults.Metrics.TotalFiles)" -ForegroundColor Cyan
Write-Host "     Total Size: $totalSizeMB MB" -ForegroundColor Cyan
Write-Host "     Python Lines: $($auditResults.Metrics.CodeLines.Python)" -ForegroundColor Cyan
Write-Host "     TypeScript Lines: $($auditResults.Metrics.CodeLines.TypeScript)" -ForegroundColor Cyan
Write-Host "     Total Code Lines: $($auditResults.Metrics.CodeLines.Total)" -ForegroundColor Cyan

Write-Host "`n  🔍 HEALTH CHECK:" -ForegroundColor White
$totalIssues = $auditResults.Issues.Count
$totalWarnings = $auditResults.Warnings.Count
Write-Host "     Errors: $totalIssues" -ForegroundColor $(if ($totalIssues -gt 0) { "Red" } else { "Green" })
Write-Host "     Warnings: $totalWarnings" -ForegroundColor $(if ($totalWarnings -gt 0) { "Yellow" } else { "Green" })

if ($totalIssues -gt 0) {
    Write-Host "`n  ❌ CRITICAL ISSUES:" -ForegroundColor Red
    foreach ($issue in $auditResults.Issues) {
        Write-Host "     • [$($issue.Category)] $($issue.Message)" -ForegroundColor Red
    }
}

Write-Host "`n═══════════════════════════════════════════════════════════`n" -ForegroundColor Magenta

# ===================================================
# EXPORT OPTIONS
# ===================================================

if ($ExportJson) {
    $jsonPath = "audit-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $auditResults | ConvertTo-Json -Depth 10 | Out-File $jsonPath -Encoding UTF8
    Write-Host "📄 JSON audit exported to: $jsonPath" -ForegroundColor Green
}

if ($ExportText) {
    $textPath = "REZ_HIVE_AUDIT_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $totalSizeMB = [math]::Round($auditResults.Metrics.TotalSize / 1MB, 2)
    $textContent = @"
🏛️ REZ HIVE - UNIFIED SOVEREIGN AUDIT
======================================
Generated: $($auditResults.Timestamp)
Status: $($auditResults.Status)

CODE METRICS
------------
Total Files: $($auditResults.Metrics.TotalFiles)
Total Size: $totalSizeMB MB
Python Lines: $($auditResults.Metrics.CodeLines.Python)
TypeScript Lines: $($auditResults.Metrics.CodeLines.TypeScript)

HEALTH STATUS
-------------
Errors: $totalIssues
Warnings: $totalWarnings

GENESIS LEDGER
--------------
Exists: $($auditResults.Genesis.LedgerExists)
Valid: $($auditResults.Genesis.LedgerValid)
Hash: $($auditResults.Genesis.GenesisHash)
"@
    $textContent | Out-File -FilePath $textPath -Encoding UTF8
    Write-Host "📄 Text audit exported to: $textPath" -ForegroundColor Green
}

# ===================================================
# AUTO-FIX
# ===================================================

if ($FixIssues -and $totalIssues -gt 0) {
    Write-Host "`n🔧 AUTO-FIX MODE" -ForegroundColor Yellow
    Write-Host "Attempting to fix common issues...`n"
    
    # Create missing folders
    $requiredFolders = @("backend", "frontend", "scripts", "docs", "logs")
    foreach ($folder in $requiredFolders) {
        if (!(Test-Path $folder)) {
            New-Item -ItemType Directory -Path $folder -Force | Out-Null
            Write-Host "  ✅ Created: $folder" -ForegroundColor Green
        }
    }
    
    # Copy .env
    if (!(Test-Path "backend/.env") -and (Test-Path "backend/.env.example")) {
        Copy-Item "backend/.env.example" "backend/.env"
        Write-Host "  ✅ Created backend/.env" -ForegroundColor Green
    }
    
    Write-Host "`n✅ Auto-fix complete!" -ForegroundColor Green
}

# Return exit code
if ($auditResults.Status -eq "PASS") { exit 0 } else { exit 1 }