# 🏛️ ADD SYSTEM MONITOR TO ROUTER
$routerPath = "src\lib\okiru-engine.ts"
$content = Get-Content $routerPath -Raw

# Define the new rule
$systemRule = @'

  // PRIORITY 3.6: SYSTEM MONITOR (PC Dashboard)
  else if (t.includes('system health') || t.includes('pc stats') || t.includes('vitals') || t.includes('dashboard')) {
    worker = 'system_monitor';
  }
'@

# Insert after the VOICE section (PRIORITY 3.5)
if ($content -match '(// PRIORITY 3.5: VOICE.*?\n.*?\n)') {
    $newContent = $content -replace $matches[1], $matches[1] + $systemRule
    Set-Content -Path $routerPath -Value $newContent -Encoding UTF8
    Write-Host "✅ System monitor rule added to router" -ForegroundColor Green
} else {
    Write-Host "⚠️ Could not find VOICE section. Adding at the end..." -ForegroundColor Yellow
    # Add before the default return
    $newContent = $content -replace '(console\.log\(.*?\);?\s*return { worker, intent: task };)', $systemRule + "`n  `$1"
    Set-Content -Path $routerPath -Value $newContent -Encoding UTF8
    Write-Host "✅ System monitor rule added at the end" -ForegroundColor Green
}

# Verify it was added
Write-Host "`n🔍 Verifying router update:" -ForegroundColor Cyan
Select-String -Path $routerPath -Pattern "system_monitor" -Context 2,2