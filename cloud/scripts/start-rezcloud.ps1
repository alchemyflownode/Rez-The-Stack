#!/usr/bin/env pwsh
# start-rezcloud.ps1 - Start all cloud services

$CloudRoot = "D:\okiru-os\The Reztack OS\cloud"

Write-Host "Starting REZCLOUDLOCAL services..." -ForegroundColor Cyan

# Start Nextcloud
Set-Location "$CloudRoot\nextcloud"
docker compose up -d
Write-Host "  Nextcloud started" -ForegroundColor Green

# Start Jellyfin
Set-Location "$CloudRoot\jellyfin"
docker compose up -d
Write-Host "  Jellyfin started" -ForegroundColor Green

Write-Host ""
Write-Host "Access URLs:" -ForegroundColor Yellow
Write-Host "  Nextcloud: http://localhost:8080" -ForegroundColor Cyan
Write-Host "  Jellyfin:  http://localhost:8096" -ForegroundColor Cyan
