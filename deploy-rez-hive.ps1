# ================================================
# 🏛️ REZ GOLDEN RULE
# No component may execute without structured output.
# No structured output may bypass audit.
# No action may bypass the Config Layer.
# ================================================
# ðŸ›ï¸ REZ HIVE - DEPLOYMENT SCRIPT
param(
    [string]$SourcePath = "/mnt/kimi/output/rez_hive_system",
    [string]$DestPath = "G:\okiru\app builder\Cognitive Kernel"
)

Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  DEPLOYING REZ HIVE SYSTEM" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Magenta

# Create destination directories
New-Item -ItemType Directory -Path "$DestPath\src\api\workers" -Force | Out-Null
New-Item -ItemType Directory -Path "$DestPath\src\components" -Force | Out-Null
New-Item -ItemType Directory -Path "$DestPath\src\app\api\system\snapshot" -Force | Out-Null
New-Item -ItemType Directory -Path "$DestPath\audit" -Force | Out-Null

# Copy files
Copy-Item "$SourcePath\src\api\workers\search_harvester.py" "$DestPath\src\api\workers\" -Force
Copy-Item "$SourcePath\src\api\workers\system_agent.py" "$DestPath\src\api\workers\" -Force
Copy-Item "$SourcePath\src\components\PCDashboard.tsx" "$DestPath\src\components\" -Force
Copy-Item "$SourcePath\src\components\DeepSearchResults.tsx" "$DestPath\src\components\" -Force
Copy-Item "$SourcePath\src\app\page.tsx" "$DestPath\src\app\" -Force
Copy-Item "$SourcePath\src\app\api\system\snapshot\route.ts" "$DestPath\src\app\api\system\snapshot\" -Force
Copy-Item "$SourcePath\audit\audit-all.ps1" "$DestPath\audit\" -Force

Write-Host "`nâœ… All components deployed!" -ForegroundColor Green
Write-Host ""
Write-Host "ðŸ“‹ NEXT STEPS:" -ForegroundColor Yellow
Write-Host "   1. Install Python dependencies:" -ForegroundColor White
Write-Host "      pip install psutil duckduckgo-search" -ForegroundColor Cyan
Write-Host ""
Write-Host "   2. Run the audit:" -ForegroundColor White
Write-Host "      cd audit; .\audit-all.ps1 -Deep" -ForegroundColor Cyan
Write-Host ""
Write-Host "   3. Start your server:" -ForegroundColor White
Write-Host "      `$env:NEXT_TURBOPACK=0; bun run next dev -p 3001 --webpack" -ForegroundColor Cyan
Write-Host ""
Write-Host "   4. Try commands in UI:" -ForegroundColor White
Write-Host "      â€¢ /search cyberpunk 2077  - Deep search with images" -ForegroundColor Gray
Write-Host "      â€¢ /system                  - PC dashboard" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Magenta
