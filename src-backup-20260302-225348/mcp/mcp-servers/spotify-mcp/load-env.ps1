# load-spotify-env.ps1
# Loads Spotify credentials into environment for MCP server

$envFile = "$PSScriptRoot\.env.spotify"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
        }
    }
    Write-Host "✅ Spotify environment loaded" -ForegroundColor Green
} else {
    Write-Host "⚠️ No .env.spotify found. Run setup-spotify.ps1 first." -ForegroundColor Yellow
}
