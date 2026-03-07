#!/usr/bin/env pwsh
# backup-rezcloud.ps1 - Backup all cloud data

$BackupRoot = "D:\okiru-os\The Reztack OS\cloud\backups"
$Date = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupDir = "$BackupRoot\$Date"

Write-Host "Backing up REZCLOUDLOCAL..." -ForegroundColor Cyan

New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

# Backup Nextcloud data
Write-Host "  Backing up Nextcloud..." -ForegroundColor Yellow
Copy-Item -Path "D:\okiru-os\The Reztack OS\cloud\nextcloud\data" -Destination "$BackupDir\nextcloud-data" -Recurse -Force

# Backup Jellyfin config
Write-Host "  Backing up Jellyfin config..." -ForegroundColor Yellow
Copy-Item -Path "D:\okiru-os\The Reztack OS\cloud\jellyfin\config" -Destination "$BackupDir\jellyfin-config" -Recurse -Force

# Backup secrets
Copy-Item -Path "D:\okiru-os\The Reztack OS\cloud\secrets.txt" -Destination "$BackupDir\" -Force

Write-Host "  Backup complete: $BackupDir" -ForegroundColor Green
