# start-spotify-mcp.ps1
# One-click launcher for Spotify MCP server

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFile = "$scriptDir\.env.spotify"

# Load environment
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
        }
    }
}

Write-Host "🎵 Starting Spotify MCP Server..." -ForegroundColor Cyan
python "$scriptDir\server.py"
