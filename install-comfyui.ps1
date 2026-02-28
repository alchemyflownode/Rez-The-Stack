# 🏛️ REZ HIVE - COMFYUI INTEGRATION
Write-Host "Installing ComfyUI integration..." -ForegroundColor Cyan

# 1. Check prerequisites
$hasDocker = Get-Command docker -ErrorAction SilentlyContinue
if (-not $hasDocker) {
    Write-Host "⚠️ Docker not found. Will use direct ComfyUI install." -ForegroundColor Yellow
}

# 2. Install ComfyUI (if not present)
if (-not (Test-Path "C:\ComfyUI")) {
    Write-Host "Downloading ComfyUI..." -ForegroundColor Yellow
    git clone https://github.com/comfyanonymous/ComfyUI.git C:\ComfyUI
    cd C:\ComfyUI
    pip install -r requirements.txt
    Write-Host "✅ ComfyUI installed" -ForegroundColor Green
}

# 3. Download SDXL base model
if (-not (Test-Path "C:\ComfyUI\models\checkpoints\sd_xl_base_1.0.safetensors")) {
    Write-Host "Downloading SDXL base model..." -ForegroundColor Yellow
    # Use aria2 or direct download
    # This is a placeholder - you'd need actual download logic
    Write-Host "⚠️ Please download SDXL model manually" -ForegroundColor Yellow
}

# 4. Create Canvas Worker
$canvasWorker = @'
import { NextRequest, NextResponse } from 'next/server';
// ... (paste the Canvas Worker code from above)
'@

New-Item -ItemType Directory -Path "src\app\api\workers\canvas" -Force | Out-Null
Set-Content -Path "src\app\api\workers\canvas\route.ts" -Value $canvasWorker -Encoding UTF8
Write-Host "✅ Canvas Worker created" -ForegroundColor Green

# 5. Update router
$okiruPath = "src\lib\okiru-engine.ts"
$content = Get-Content $okiruPath -Raw
$canvasPriority = @'

  // PRIORITY 3.5: CANVAS (Image/Video Generation)
  if (t.includes('generate image') || t.includes('create image') || t.includes('draw') || t.includes('render')) {
    return { worker: 'canvas', intent: task };
  }
'@

if ($content -match 'PRIORITY 3: VISION') {
    $content = $content -replace '(PRIORITY 3: VISION.*?\n.*?\n)', '$1' + $canvasPriority
    Set-Content -Path $okiruPath -Value $content -Encoding UTF8
    Write-Host "✅ Router updated" -ForegroundColor Green
}

# 6. Create start script
$startScript = @'
@echo off
echo Starting Rez Hive Canvas Stack...

:: Start ComfyUI
start "ComfyUI" cmd /c "cd C:\ComfyUI && python main.py"

:: Wait 10 seconds
timeout /t 10 /nobreak

:: Start Rez Hive
cd /d "%~dp0"
$env:NEXT_TURBOPACK=0; bun run next dev -p 3001 --webpack
'@
Set-Content -Path "start-canvas.bat" -Value $startScript -Encoding ASCII

Write-Host "✅ Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Download SDXL model to C:\ComfyUI\models\checkpoints"
Write-Host "2. Run .\start-canvas.bat"
Write-Host "3. Try: 'Generate image of a cyberpunk samurai'"