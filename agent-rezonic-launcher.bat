#Requires -Version 5.1
<#
.SYNOPSIS
    REZ HIVE Service Monitor with Clean Output
.DESCRIPTION
    Launches and monitors all REZ HIVE services with clean, formatted output
.PARAMETER FrontendPort
    Port for Next.js frontend (default: 3001)
.PARAMETER ChromaDBPort
    Port for ChromaDB (default: 8000)
.PARAMETER KernelPort
    Port for Python kernel (default: 8001)
.PARAMETER NoCleanup
    Skip killing existing processes
.PARAMETER ShowLogs
    Display service logs in real-time
.EXAMPLE
    .\Start-RezHive.ps1
.EXAMPLE
    .\Start-RezHive.ps1 -ShowLogs -FrontendPort 3000
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Frontend port")]
    [ValidateRange(3000, 9999)]
    [int]$FrontendPort = 3001,
    
    [Parameter(HelpMessage = "ChromaDB port")]
    [ValidateRange(3000, 9999)]
    [int]$ChromaDBPort = 8000,
    
    [Parameter(HelpMessage = "Kernel port")]
    [ValidateRange(3000, 9999)]
    [int]$KernelPort = 8001,
    
    [Parameter(HelpMessage = "Skip process cleanup")]
    [switch]$NoCleanup,
    
    [Parameter(HelpMessage = "Show service logs")]
    [switch]$ShowLogs,
    
    [Parameter(HelpMessage = "Maximum startup wait time in seconds")]
    [ValidateRange(5, 120)]
    [int]$StartupTimeout = 30
)

#region Configuration
$Script:Config = @{
    ProjectRoot = $PWD.Path
    Services = @{
        ChromaDB = @{
            Name = 'ChromaDB'
            Icon = '📀'
            Color = 'Magenta'
            Port = $ChromaDBPort
            ProcessName = 'python'
            StartupDelay = 5
            HealthCheck = "http://localhost:$ChromaDBPort/api/v1/heartbeat"
        }
        Kernel = @{
            Name = 'Kernel'
            Icon = '🧠'
            Color = 'Yellow'
            Port = $KernelPort
            ProcessName = 'python'
            StartupDelay = 5
            HealthCheck = "http://localhost:$KernelPort/health"
        }
        Frontend = @{
            Name = 'Frontend'
            Icon = '🎨'
            Color = 'Cyan'
            Port = $FrontendPort
            ProcessName = 'node'
            StartupDelay = 8
            HealthCheck = "http://localhost:$FrontendPort"
        }
    }
    ProcessCache = @{}
}

$ErrorActionPreference = 'Stop'
#endregion

#region Helper Functions

function Write-ServiceLog {
    param(
        [Parameter(Mandatory)]
        [string]$Service,
        
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('Info', 'Success', 'Warning', 'Error', 'Detail')]
        [string]$Level = 'Info'
    )
    
    $serviceConfig = $Config.Services[$Service]
    $icon = $serviceConfig.Icon
    $timestamp = Get-Date -Format 'HH:mm:ss'
    
    $color = switch ($Level) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        'Detail' { 'Gray' }
        default { $serviceConfig.Color }
    }
    
    $prefix = switch ($Level) {
        'Success' { '✅' }
        'Warning' { '⚠️ ' }
        'Error' { '❌' }
        'Detail' { '  ' }
        default { $icon }
    }
    
    Write-Host "[$timestamp] $prefix " -NoNewline -ForegroundColor DarkGray
    Write-Host "$($serviceConfig.Name): " -NoNewline -ForegroundColor $color
    Write-Host $Message -ForegroundColor White
}

function Test-PortAvailable {
    param(
        [Parameter(Mandatory)]
        [int]$Port
    )
    
    try {
        $connection = New-Object System.Net.Sockets.TcpClient
        $connection.Connect('127.0.0.1', $Port)
        $connection.Close()
        return $false  # Port is in use
    }
    catch {
        return $true   # Port is available
    }
}

function Wait-ForService {
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName,
        
        [Parameter(Mandatory)]
        [int]$Port,
        
        [int]$TimeoutSeconds = 30,
        
        [string]$HealthCheckUrl
    )
    
    $elapsed = 0
    $interval = 1
    
    Write-ServiceLog -Service $ServiceName -Message "Waiting for service to be ready..." -Level Detail
    
    while ($elapsed -lt $TimeoutSeconds) {
        # Check if port is listening
        if (-not (Test-PortAvailable -Port $Port)) {
            # Port is in use, now check health endpoint if provided
            if ($HealthCheckUrl) {
                try {
                    $response = Invoke-WebRequest -Uri $HealthCheckUrl -Method Get -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
                    if ($response.StatusCode -eq 200) {
                        Write-ServiceLog -Service $ServiceName -Message "Service is healthy" -Level Success
                        return $true
                    }
                }
                catch {
                    # Health check failed, continue waiting
                }
            }
            else {
                # No health check, just verify port is listening
                Write-ServiceLog -Service $ServiceName -Message "Port $Port is listening" -Level Success
                return $true
            }
        }
        
        Start-Sleep -Seconds $interval
        $elapsed += $interval
        
        # Show progress every 5 seconds
        if ($elapsed % 5 -eq 0) {
            Write-ServiceLog -Service $ServiceName -Message "Still waiting... ($elapsed/$TimeoutSeconds seconds)" -Level Detail
        }
    }
    
    Write-ServiceLog -Service $ServiceName -Message "Timeout waiting for service" -Level Error
    return $false
}

function Stop-ServiceProcesses {
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName
    )
    
    $processes = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    
    if ($processes) {
        Write-Host "   Stopping $(@($processes).Count) $ProcessName process(es)..." -ForegroundColor Gray
        
        foreach ($proc in $processes) {
            try {
                $proc.Kill()
                $proc.WaitForExit(5000)
                Write-Host "   ✓ Stopped PID $($proc.Id)" -ForegroundColor DarkGray
            }
            catch {
                Write-Host "   ! Failed to stop PID $($proc.Id)" -ForegroundColor DarkYellow
            }
        }
        
        Start-Sleep -Seconds 1
    }
}

function Start-ChromaDB {
    param([int]$Port)
    
    $serviceName = 'ChromaDB'
    Write-ServiceLog -Service $serviceName -Message "Starting on port $Port..."
    
    # Build command with clean output
    $command = @"
`$Host.UI.RawUI.WindowTitle = 'REZ HIVE - ChromaDB'
`$env:PYTHONIOENCODING = 'utf-8'
`$env:PYTHONUNBUFFERED = '1'

# Suppress ANSI codes on Windows
`$env:NO_COLOR = '1'
`$env:TERM = 'dumb'

Write-Host '═══════════════════════════════════════════' -ForegroundColor Magenta
Write-Host '   📀 ChromaDB Server' -ForegroundColor Magenta
Write-Host '═══════════════════════════════════════════' -ForegroundColor Magenta
Write-Host ''

chroma run --path ./chroma_data --port $Port --log-level WARNING 2>&1 | ForEach-Object {
    # Strip ANSI escape sequences
    `$line = `$_ -replace '\x1b\[[0-9;]*[a-zA-Z]', ''
    if (`$line -match 'uvicorn.error|Connect to Chroma|http://') {
        Write-Host `$line -ForegroundColor White
    }
}
"@
    
    $process = Start-Process powershell -WindowStyle Normal `
        -ArgumentList "-NoExit", "-NoProfile", "-Command", $command `
        -PassThru
    
    $Config.ProcessCache[$serviceName] = $process
    
    # Wait for service
    Start-Sleep -Seconds $Config.Services[$serviceName].StartupDelay
    
    if (Wait-ForService -ServiceName $serviceName -Port $Port -TimeoutSeconds $StartupTimeout) {
        Write-ServiceLog -Service $serviceName -Message "Running (PID: $($process.Id))" -Level Success
        return $process
    }
    else {
        Write-ServiceLog -Service $serviceName -Message "Failed to start properly" -Level Error
        return $null
    }
}

function Start-Kernel {
    param([int]$Port)
    
    $serviceName = 'Kernel'
    Write-ServiceLog -Service $serviceName -Message "Starting Python backend..."
    
    $command = @"
`$Host.UI.RawUI.WindowTitle = 'REZ HIVE - Kernel'
`$env:PYTHONIOENCODING = 'utf-8'
`$env:PYTHONUNBUFFERED = '1'

Write-Host '═══════════════════════════════════════════' -ForegroundColor Yellow
Write-Host '   🧠 Kernel Backend' -ForegroundColor Yellow
Write-Host '═══════════════════════════════════════════' -ForegroundColor Yellow
Write-Host ''

cd '$($Config.ProjectRoot)'
python backend/kernel.py 2>&1 | ForEach-Object {
    if (`$_ -match 'ERROR|WARNING|INFO|⏱️|✅') {
        Write-Host `$_ -ForegroundColor White
    } elseif (`$_ -match 'Started server|Uvicorn running') {
        Write-Host `$_ -ForegroundColor Green
    } else {
        Write-Host `$_ -ForegroundColor Gray
    }
}
"@
    
    $process = Start-Process powershell -WindowStyle Normal `
        -ArgumentList "-NoExit", "-NoProfile", "-Command", $command `
        -PassThru
    
    $Config.ProcessCache[$serviceName] = $process
    
    # Wait for service
    Start-Sleep -Seconds $Config.Services[$serviceName].StartupDelay
    
    if (Wait-ForService -ServiceName $serviceName -Port $Port -TimeoutSeconds $StartupTimeout) {
        Write-ServiceLog -Service $serviceName -Message "Running (PID: $($process.Id))" -Level Success
        return $process
    }
    else {
        Write-ServiceLog -Service $serviceName -Message "Failed to start properly" -Level Error
        return $null
    }
}

function Start-Frontend {
    param([int]$Port)
    
    $serviceName = 'Frontend'
    Write-ServiceLog -Service $serviceName -Message "Starting Next.js on port $Port..."
    
    $command = @"
`$Host.UI.RawUI.WindowTitle = 'REZ HIVE - Frontend'
`$env:NODE_ENV = 'development'
`$env:FORCE_COLOR = '1'

Write-Host '═══════════════════════════════════════════' -ForegroundColor Cyan
Write-Host '   🎨 Next.js Frontend' -ForegroundColor Cyan
Write-Host '═══════════════════════════════════════════' -ForegroundColor Cyan
Write-Host ''

cd '$($Config.ProjectRoot)'
npm run dev -- -p $Port 2>&1 | ForEach-Object {
    if (`$_ -match 'ready|compiled|Local:|Network:') {
        Write-Host `$_ -ForegroundColor Green
    } elseif (`$_ -match 'error|Error|ERROR') {
        Write-Host `$_ -ForegroundColor Red
    } elseif (`$_ -match 'warn|warning|WARNING') {
        Write-Host `$_ -ForegroundColor Yellow
    } else {
        Write-Host `$_ -ForegroundColor White
    }
}
"@
    
    $process = Start-Process powershell -WindowStyle Normal `
        -ArgumentList "-NoExit", "-NoProfile", "-Command", $command `
        -PassThru
    
    $Config.ProcessCache[$serviceName] = $process
    
    # Wait for service
    Start-Sleep -Seconds $Config.Services[$serviceName].StartupDelay
    
    if (Wait-ForService -ServiceName $serviceName -Port $Port -TimeoutSeconds $StartupTimeout) {
        Write-ServiceLog -Service $serviceName -Message "Running (PID: $($process.Id))" -Level Success
        return $process
    }
    else {
        Write-ServiceLog -Service $serviceName -Message "Failed to start properly" -Level Error
        return $null
    }
}

function Test-ServiceHealth {
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName,
        
        [Parameter(Mandatory)]
        [string]$Url
    )
    
    try {
        $response = Invoke-WebRequest -Uri $Url -Method Get -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
        Write-ServiceLog -Service $ServiceName -Message "Health check passed (HTTP $($response.StatusCode))" -Level Success
        return $true
    }
    catch {
        Write-ServiceLog -Service $ServiceName -Message "Health check failed: $($_.Exception.Message)" -Level Warning
        return $false
    }
}

#endregion

#region Main Execution

try {
    # Header
    Clear-Host
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║        🏛️  REZ HIVE - SERVICE LAUNCHER v2.0                  ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # Cleanup existing processes
    if (-not $NoCleanup) {
        Write-Host "🧹 Cleaning up existing processes..." -ForegroundColor Yellow
        Write-Host ""
        
        Stop-ServiceProcesses -ProcessName 'python'
        Stop-ServiceProcesses -ProcessName 'node'
        
        # Wait for ports to be released
        Start-Sleep -Seconds 2
        Write-Host ""
    }
    
    # Verify ports are available
    Write-Host "🔍 Verifying ports..." -ForegroundColor Yellow
    $portsToCheck = @($ChromaDBPort, $KernelPort, $FrontendPort)
    $allPortsAvailable = $true
    
    foreach ($port in $portsToCheck) {
        if (-not (Test-PortAvailable -Port $port)) {
            Write-Host "   ❌ Port $port is already in use" -ForegroundColor Red
            $allPortsAvailable = $false
        }
        else {
            Write-Host "   ✓ Port $port is available" -ForegroundColor Green
        }
    }
    
    if (-not $allPortsAvailable) {
        throw "Some ports are unavailable. Use -NoCleanup to skip cleanup, or change ports."
    }
    
    Write-Host ""
    Write-Host "🚀 Starting services..." -ForegroundColor Cyan
    Write-Host ""
    
    # Start services in order
    $chromaProcess = Start-ChromaDB -Port $ChromaDBPort
    if (-not $chromaProcess) {
        throw "Failed to start ChromaDB"
    }
    
    Write-Host ""
    
    $kernelProcess = Start-Kernel -Port $KernelPort
    if (-not $kernelProcess) {
        throw "Failed to start Kernel"
    }
    
    Write-Host ""
    
    $frontendProcess = Start-Frontend -Port $FrontendPort
    if (-not $frontendProcess) {
        throw "Failed to start Frontend"
    }
    
    # Summary
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║        ✅ ALL SERVICES RUNNING                                ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "🌐 Service URLs:" -ForegroundColor Cyan
    Write-Host "   Frontend:   " -NoNewline -ForegroundColor White
    Write-Host "http://localhost:$FrontendPort" -ForegroundColor Green
    Write-Host "   Metrics:    " -NoNewline -ForegroundColor White
    Write-Host "http://localhost:$FrontendPort/api/vitals" -ForegroundColor Green
    Write-Host "   Kernel:     " -NoNewline -ForegroundColor White
    Write-Host "http://localhost:$KernelPort" -ForegroundColor Green
    Write-Host "   ChromaDB:   " -NoNewline -ForegroundColor White
    Write-Host "http://localhost:$ChromaDBPort" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "📊 Process IDs:" -ForegroundColor Cyan
    Write-Host "   ChromaDB:   PID $($chromaProcess.Id)" -ForegroundColor Gray
    Write-Host "   Kernel:     PID $($kernelProcess.Id)" -ForegroundColor Gray
    Write-Host "   Frontend:   PID $($frontendProcess.Id)" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "💡 Tips:" -ForegroundColor Yellow
    Write-Host "   • Press Ctrl+C in service windows to stop" -ForegroundColor White
    Write-Host "   • Run './Stop-RezHive.ps1' to stop all services" -ForegroundColor White
    Write-Host "   • Check logs in the service windows" -ForegroundColor White
    Write-Host ""
    
    # Optional: Run health checks
    if ($ShowLogs) {
        Write-Host "🏥 Running health checks..." -ForegroundColor Cyan
        Write-Host ""
        
        Start-Sleep -Seconds 3
        
        foreach ($service in $Config.Services.Keys) {
            $serviceConfig = $Config.Services[$service]
            if ($serviceConfig.HealthCheck) {
                Test-ServiceHealth -ServiceName $service -Url $serviceConfig.HealthCheck
            }
        }
        
        Write-Host ""
    }
    
    # Keep script running to monitor
    Write-Host "Press any key to exit monitor..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}
catch {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║        ❌ STARTUP FAILED                                      ║" -ForegroundColor Red
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Stack trace:" -ForegroundColor Gray
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    
    exit 1
}

#endregion