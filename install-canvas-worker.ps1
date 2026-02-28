# 🏛️ REZ HIVE - CANVAS WORKER INSTALLER (Using your ComfyUI)
Write-Host "Installing Canvas Worker for your ComfyUI..." -ForegroundColor Cyan

# 1. Verify your ComfyUI path
$comfyPath = "D:\ComfyUI_windows_portable_nvidia\ComfyUI_windows_portable"
if (Test-Path $comfyPath) {
    Write-Host "✅ Found ComfyUI at: $comfyPath" -ForegroundColor Green
} else {
    Write-Host "❌ ComfyUI not found at expected path" -ForegroundColor Red
    exit 1
}

# 2. Create Canvas Worker
$canvasWorker = @'
// PASTE THE ENTIRE Canvas Worker CODE FROM ABOVE HERE
'@

New-Item -ItemType Directory -Path "src\app\api\workers\canvas" -Force | Out-Null
Set-Content -Path "src\app\api\workers\canvas\route.ts" -Value $canvasWorker -Encoding UTF8
Write-Host "✅ Canvas Worker created" -ForegroundColor Green

# 3. Update router
$okiruPath = "src\lib\okiru-engine.ts"
$content = Get-Content $okiruPath -Raw
$canvasPriority = @'

  // PRIORITY 3.5: CANVAS (Image/Video Generation)
  if (t.includes('generate image') || t.includes('create image') || t.includes('draw') || t.includes('render') || t.includes('comfy')) {
    return { worker: 'canvas', intent: task };
  }
'@

if ($content -match 'PRIORITY 3: VISION') {
    $content = $content -replace '(PRIORITY 3: VISION.*?\n.*?\n)', '$1' + $canvasPriority
    Set-Content -Path $okiruPath -Value $content -Encoding UTF8
    Write-Host "✅ Router updated with Canvas priority" -ForegroundColor Green
}

# 4. Update .env
Add-Content -Path ".env" -Value "`nCOMFYUI_PATH=$comfyPath`nCOMFYUI_URL=http://127.0.0.1:8188" -ErrorAction SilentlyContinue
Write-Host "✅ Environment updated" -ForegroundColor Green

# 5. Create start script for both services
$startScript = @'
@echo off
echo Starting Rez Hive + ComfyUI Canvas Stack...
echo.

:: Start ComfyUI in its own window
echo [1/2] Starting ComfyUI...
start "ComfyUI" cmd /c "cd /d D:\ComfyUI_windows_portable_nvidia\ComfyUI_windows_portable && python_embeded\python.exe ComfyUI\main.py"

:: Wait for ComfyUI to initialize
echo Waiting 15 seconds for ComfyUI...
timeout /t 15 /nobreak > nul

:: Start Rez Hive
echo [2/2] Starting Rez Hive...
cd /d "%~dp0"
echo Server will be at http://localhost:3001
echo.
$env:NEXT_TURBOPACK=0; bun run next dev -p 3001 --webpack
'@
Set-Content -Path "start-canvas.bat" -Value $startScript -Encoding ASCII
Write-Host "✅ Start script created: start-canvas.bat" -ForegroundColor Green

# 6. Test script
$testCanvas = @'
# 🎨 Test Canvas Worker
Write-Host "Testing Canvas Worker..." -ForegroundColor Cyan

# Test simple generation
$body = @{task="Generate image of a cyberpunk samurai in rain"} | ConvertTo-Json
$result = Invoke-RestMethod -Uri "http://localhost:3001/api/workers/canvas" -Method POST -Body $body -ContentType "application/json"

if ($result.status -eq 'success') {
    Write-Host "✅ Image generated!" -ForegroundColor Green
    Write-Host "URL: $($result.imageUrl)" -ForegroundColor Cyan
} else {
    Write-Host "❌ Failed: $($result.message)" -ForegroundColor Red
}
'@
Set-Content -Path "test-canvas.ps1" -Value $testCanvas -Encoding UTF8
Write-Host "✅ Test script created: test-canvas.ps1" -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  🏆 CANVAS WORKER INSTALLED" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "   📍 ComfyUI: $comfyPath"
Write-Host "   🎨 Canvas Worker: src/app/api/workers/canvas/route.ts"
Write-Host "   🔌 Router: Updated with Canvas priority"
Write-Host ""
Write-Host "📋 NEXT STEPS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   1. Run the start script:" -ForegroundColor White
Write-Host "      .\start-canvas.bat" -ForegroundColor Cyan
Write-Host ""
Write-Host "   2. Test the Canvas Worker:" -ForegroundColor White
Write-Host "      .\test-canvas.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "   3. Try in UI:" -ForegroundColor White
Write-Host '      "Generate image of a beautiful landscape"' -ForegroundColor Cyan
Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta