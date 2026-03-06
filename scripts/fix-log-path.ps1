# fix-log-path.ps1
$scriptPath = "setup-rez-hive.ps1"
$content = Get-Content $scriptPath -Raw

# Fix the Add-Content line - add quotes around $LogFile
$fixed = $content -replace 'Add-Content -Path \$LogFile -Value \$logMessage', 'Add-Content -Path "$LogFile" -Value $logMessage'

# Also fix any other instances where $LogFile might be used without quotes
$fixed = $fixed -replace 'Test-Path \$LogFile', 'Test-Path "$LogFile"'

$fixed | Out-File -FilePath $scriptPath -Encoding utf8 -Force

Write-Host "✅ Fixed log path references in script" -ForegroundColor Green