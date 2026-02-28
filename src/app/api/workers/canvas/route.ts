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
