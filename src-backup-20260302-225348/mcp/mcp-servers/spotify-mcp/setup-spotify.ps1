# setup-spotify.ps1
# Helps you set up Spotify Developer credentials

Write-Host "🎵 Spotify MCP Setup" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Step 1: Go to https://developer.spotify.com/dashboard" -ForegroundColor Yellow
Write-Host "Step 2: Click 'Create App'" -ForegroundColor Yellow
Write-Host "Step 3: Fill in:" -ForegroundColor Yellow
Write-Host "   App name: RezStack Sovereign" -ForegroundColor White
Write-Host "   Description: Local AI music control" -ForegroundColor White
Write-Host "   Redirect URI: http://localhost:8888/callback" -ForegroundColor White
Write-Host "Step 4: Copy your Client ID and Client Secret" -ForegroundColor Yellow
Write-Host ""

$clientId = Read-Host "Enter your Spotify Client ID"
$clientSecret = Read-Host "Enter your Spotify Client Secret"

# Save to .env
@"
SPOTIFY_CLIENT_ID=$clientId
SPOTIFY_CLIENT_SECRET=$clientSecret
"@ | Out-File "$PSScriptRoot\.env.spotify" -Encoding UTF8

# Also save to parent .env for MCP to find
@"
SPOTIFY_CLIENT_ID=$clientId
SPOTIFY_CLIENT_SECRET=$clientSecret
"@ | Out-File "$PSScriptRoot\..\..\.env.spotify" -Encoding UTF8

Write-Host ""
Write-Host "✅ Credentials saved to .env.spotify" -ForegroundColor Green
Write-Host "   Add these to your environment or use them in the server." -ForegroundColor Gray
