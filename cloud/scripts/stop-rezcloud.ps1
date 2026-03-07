#!/usr/bin/env pwsh
# stop-rezcloud.ps1 - Stop all cloud services

$CloudRoot = "D:\okiru-os\The Reztack OS\cloud"

Write-Host "Stopping REZCLOUDLOCAL services..." -ForegroundColor Cyan

# Stop Nextcloud
Set-Location "$CloudRoot\nextcloud"
docker compose down
Write-Host "  Nextcloud stopped" -ForegroundColor Green

# Stop Jellyfin
Set-Location "$CloudRoot\jellyfin"
docker compose down
Write-Host "  Jellyfin stopped" -ForegroundColor Green
