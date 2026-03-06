# PASTE AND RUN THE ENTIRE SCRIPT BLOCK
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "Installing Canvas Worker for your ComfyUI..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Magenta

# 1. Verify your ComfyUI path
 $comfyPath = "D:\ComfyUI_windows_portable_nvidia\ComfyUI_windows_portable"
if (Test-Path $comfyPath) {
    Write-Host "`n✅ Found ComfyUI at: $comfyPath" -ForegroundColor Green
} else {
    Write-Host "`n❌ ComfyUI not found at expected path" -ForegroundColor Red
    exit 1
}

# 2. Create Canvas Worker
Write-Host "`n📝 Creating Canvas Worker..." -ForegroundColor Yellow

 $canvasWorker = @'
import { NextRequest, NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';
import { writeFile, mkdir, readFile } from 'fs/promises';
import { join } from 'path';
import { randomUUID } from 'crypto';
import { existsSync } from 'fs';

const execAsync = promisify(exec);

// ========== YOUR CUSTOM PATHS ==========
const COMFYUI_BASE = 'D:/ComfyUI_windows_portable_nvidia/ComfyUI_windows_portable';
const COMFYUI_PYTHON = join(COMFYUI_BASE, 'python_embeded', 'python.exe');
const COMFYUI_MAIN = join(COMFYUI_BASE, 'ComfyUI', 'main.py');
const COMFYUI_OUTPUT = join(COMFYUI_BASE, 'ComfyUI', 'output');
const COMFYUI_URL = 'http://127.0.0.1:8188';

// Check if ComfyUI is running
async function isComfyUIRunning() {
  try {
    const response = await fetch(`${COMFYUI_URL}/object_info`);
    return response.ok;
  } catch {
    return false;
  }
}

// Start ComfyUI if not running
async function ensureComfyUI() {
  const running = await isComfyUIRunning();
  if (!running) {
    console.log('[Canvas Worker] Starting ComfyUI...');
    // Launch in background (detached)
    const cmd = `start /B "" "${COMFYUI_PYTHON}" "${COMFYUI_MAIN}"`;
    exec(cmd, { detached: true, stdio: 'ignore' });
    
    // Wait for it to start (up to 30 seconds)
    for (let i = 0; i < 30; i++) {
      await new Promise(r => setTimeout(r, 1000));
      if (await isComfyUIRunning()) {
        console.log('[Canvas Worker] ComfyUI ready');
        return true;
      }
    }
    throw new Error('ComfyUI failed to start');
  }
  return true;
}

export async function POST(request: NextRequest) {
  try {
    const { task, scene, model = 'sd_xl_base_1.0.safetensors' } = await request.json();
    
    // Ensure ComfyUI is running
    await ensureComfyUI();
    
    // Build workflow
    let workflow;
    
    if (scene) {
      // SCE JSON from Director
      workflow = await convertSCEtoWorkflow(scene, model);
    } else {
      // Simple txt2img
      workflow = {
        "3": {
          "class_type": "KSampler",
          "inputs": {
            "seed": Math.floor(Math.random() * 1000000),
            "steps": 20,
            "cfg": 7,
            "sampler_name": "euler",
            "scheduler": "normal",
            "denoise": 1,
            "model": ["4", 0],
            "positive": ["6", 0],
            "negative": ["7", 0],
            "latent_image": ["5", 0]
          }
        },
        "4": {
          "class_type": "CheckpointLoaderSimple",
          "inputs": { "ckpt_name": model }
        },
        "5": {
          "class_type": "EmptyLatentImage",
          "inputs": { "width": 1024, "height": 1024, "batch_size": 1 }
        },
        "6": {
          "class_type": "CLIPTextEncode",
          "inputs": { "text": task, "clip": ["4", 1] }
        },
        "7": {
          "class_type": "CLIPTextEncode",
          "inputs": { "text": "", "clip": ["4", 1] }
        },
        "8": {
          "class_type": "VAEDecode",
          "inputs": { "samples": ["3", 0], "vae": ["4", 2] }
        },
        "9": {
          "class_type": "SaveImage",
          "inputs": { 
            "filename_prefix": `rez_hive_${Date.now()}`,
            "images": ["8", 0] 
          }
        }
      };
    }
    
    // Send to ComfyUI
    const response = await fetch(`${COMFYUI_URL}/prompt`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ prompt: workflow })
    });
    
    if (!response.ok) {
      const error = await response.text();
      throw new Error(`ComfyUI error: ${error}`);
    }
    
    const { prompt_id } = await response.json();
    
    // Poll for completion
    let imagePath = null;
    let attempts = 0;
    while (attempts < 30) {
      await new Promise(r => setTimeout(r, 1000));
      
      const historyRes = await fetch(`${COMFYUI_URL}/history/${prompt_id}`);
      const history = await historyRes.json();
      
      if (history[prompt_id]?.outputs) {
        const output = history[prompt_id].outputs;
        const saveNode = Object.values(output).find((v: any) => v.images);
        if (saveNode) {
          const image = saveNode.images[0];
          imagePath = `/api/canvas/image/${image.filename}`;
          break;
        }
      }
      attempts++;
    }
    
    return NextResponse.json({
      status: 'success',
      worker: 'canvas',
      prompt: task,
      imageUrl: imagePath,
      model: model,
      comfyui: COMFYUI_BASE
    });
    
  } catch (error: any) {
    console.error('[Canvas Worker] Error:', error);
    return NextResponse.json({ 
      status: 'error', 
      message: error.message 
    }, { status: 500 });
  }
}

// Serve generated images
export async function GET(request: NextRequest) {
  const filename = request.nextUrl.pathname.split('/').pop();
  const imagePath = join(COMFYUI_OUTPUT, filename || '');
  
  try {
    const image = await readFile(imagePath);
    return new NextResponse(image, {
      headers: { 
        'Content-Type': 'image/png',
        'Cache-Control': 'public, max-age=3600'
      }
    });
  } catch {
    return NextResponse.json({ error: 'Image not found' }, { status: 404 });
  }
}

async function convertSCEtoWorkflow(sce: any, model: string) {
  const prompt = sce.meta?.topic || sce.segments?.[0]?.title || 'A beautiful scene';
  
  return {
    "3": {
      "class_type": "KSampler",
      "inputs": {
        "seed": Math.floor(Math.random() * 1000000),
        "steps": 30,
        "cfg": 7,
        "sampler_name": "dpmpp_2m",
        "scheduler": "karras",
        "denoise": 1,
        "model": ["4", 0],
        "positive": ["6", 0],
        "negative": ["7", 0],
        "latent_image": ["5", 0]
      }
    },
    "4": {
      "class_type": "CheckpointLoaderSimple",
      "inputs": { "ckpt_name": model }
    },
    "5": {
      "class_type": "EmptyLatentImage",
      "inputs": { "width": 1024, "height": 1024, "batch_size": 1 }
    },
    "6": {
      "class_type": "CLIPTextEncode",
      "inputs": { "text": prompt, "clip": ["4", 1] }
    },
    "7": {
      "class_type": "CLIPTextEncode",
      "inputs": { "text": "", "clip": ["4", 1] }
    },
    "8": {
      "class_type": "VAEDecode",
      "inputs": { "samples": ["3", 0], "vae": ["4", 2] }
    },
    "9": {
      "class_type": "SaveImage",
      "inputs": { 
        "filename_prefix": `sce_${Date.now()}`,
        "images": ["8", 0] 
      }
    }
  };
}
'@

New-Item -ItemType Directory -Path "src\app\api\workers\canvas" -Force | Out-Null
Set-Content -Path "src\app\api\workers\canvas\route.ts" -Value $canvasWorker -Encoding UTF8
Write-Host "✅ Canvas Worker created" -ForegroundColor Green

# 3. Update router
Write-Host "`n🔌 Updating Router..." -ForegroundColor Yellow

 $okiruPath = "src\lib\okiru-engine.ts"
if (Test-Path $okiruPath) {
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
        Write-Host "   ✅ Router updated with Canvas priority" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ Could not find VISION priority in router" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ⚠️ Router file not found" -ForegroundColor Yellow
}

# 4. Update .env
Write-Host "`n🌍 Updating Environment..." -ForegroundColor Yellow
Add-Content -Path ".env" -Value "`nCOMFYUI_PATH=$comfyPath`nCOMFYUI_URL=http://127.0.0.1:8188" -ErrorAction SilentlyContinue
Write-Host "   ✅ Environment updated" -ForegroundColor Green

# 5. Create start script for both services
Write-Host "`n🚀 Creating Start Script..." -ForegroundColor Yellow

 $startScript = @'
@echo off
echo ========================================
echo Starting Rez Hive + ComfyUI Canvas Stack
echo ========================================
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
Write-Host "   ✅ Start script created: start-canvas.bat" -ForegroundColor Green

# 6. Create test script
Write-Host "`n🧪 Creating Test Script..." -ForegroundColor Yellow

 $testCanvas = @'
# 🎨 Test Canvas Worker
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "Testing Canvas Worker..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Magenta

# Test simple generation
 $body = @{task="Generate image of a cyberpunk samurai in rain"} | ConvertTo-Json
try {
    $result = Invoke-RestMethod -Uri "http://localhost:3001/api/workers/canvas" -Method POST -Body $body -ContentType "application/json" -TimeoutSec 60

    if ($result.status -eq 'success') {
        Write-Host "`n✅ Image generated!" -ForegroundColor Green
        Write-Host "   URL: http://localhost:3001$($result.imageUrl)" -ForegroundColor Cyan
    } else {
        Write-Host "`n❌ Failed: $($result.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "`n❌ Error: $_" -ForegroundColor Red
}
'@
Set-Content -Path "test-canvas.ps1" -Value $testCanvas -Encoding UTF8
Write-Host "   ✅ Test script created: test-canvas.ps1" -ForegroundColor Green

# 7. FINAL SUMMARY
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