# setup-rez-hive-backend.ps1 - CLEAN VERSION
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "     REZ HIVE - BACKEND SETUP                         " -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

$PROJECT_PATH = "D:\okiru-os\The Reztack OS"
Set-Location $PROJECT_PATH

# ============================================
# STEP 1: Install Python Dependencies
# ============================================
Write-Host "[1/5] Installing Python dependencies..." -ForegroundColor Yellow
pip install fastapi uvicorn python-multipart ollama chromadb pydantic
Write-Host "   Done - Dependencies installed" -ForegroundColor Green

# ============================================
# STEP 2: Create Backend Directory
# ============================================
Write-Host "[2/5] Creating backend structure..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path "backend" -Force | Out-Null
New-Item -ItemType Directory -Path "chroma_data" -Force | Out-Null
Write-Host "   Done - Backend directory created" -ForegroundColor Green

# ============================================
# STEP 3: Create Kernel.py (The Brain)
# ============================================
Write-Host "[3/5] Creating kernel.py..." -ForegroundColor Yellow

$kernelContent = @'
# backend/kernel.py
import os
import sys
import json
import subprocess
import time
from datetime import datetime
from typing import Optional, Dict, Any
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# Try importing optional dependencies
try:
    import chromadb
    from chromadb.config import Settings
    CHROMA_AVAILABLE = True
except ImportError:
    CHROMA_AVAILABLE = False
    print("Warning: chromadb not installed")

try:
    from ollama import Client
    OLLAMA_AVAILABLE = True
except ImportError:
    OLLAMA_AVAILABLE = False
    print("Warning: ollama not installed")

# --- CONFIGURATION ---
app = FastAPI(title="REZ HIVE Kernel")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://127.0.0.1:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Ollama
ollama = None
if OLLAMA_AVAILABLE:
    try:
        ollama = Client(host="http://localhost:11434")
        print("Ollama client initialized")
    except Exception as e:
        print(f"Ollama connection warning: {e}")

# Initialize ChromaDB
chroma_client = None
memory_collection = None
if CHROMA_AVAILABLE:
    try:
        chroma_client = chromadb.PersistentClient(path="./chroma_data")
        memory_collection = chroma_client.get_or_create_collection(name="hive_memory")
        print("ChromaDB initialized")
    except Exception as e:
        print(f"ChromaDB warning: {e}")

# --- DATA MODELS ---
class TaskRequest(BaseModel):
    task: str
    worker: str = "brain"
    payload: Optional[Dict[str, Any]] = None

class TaskResponse(BaseModel):
    content: str
    status: str = "success"
    model: Optional[str] = None
    latency: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None

# --- TOOLS ---
def system_tool(action: str):
    safe_commands = {
        "cpu_usage": "wmic cpu get loadpercentage /value",
        "ram_usage": "wmic OS get FreePhysicalMemory,TotalVisibleMemorySize /Value",
        "list_files": "dir /B",
        "whoami": "whoami",
        "ipconfig": "ipconfig",
        "date": "date /t",
        "time": "time /t"
    }
    try:
        if action in safe_commands:
            result = subprocess.check_output(
                safe_commands[action],
                shell=True,
                text=True,
                timeout=10,
                stderr=subprocess.DEVNULL
            )
            return result.strip()
        return f"Unknown action: {action}"
    except subprocess.TimeoutExpired:
        return f"Timeout: {action}"
    except Exception as e:
        return f"Error: {str(e)}"

# --- MEMORY ---
def remember(key: str, value: str):
    if not memory_collection:
        return "Memory offline"
    try:
        doc_id = f"mem_{int(time.time() * 1000)}"
        memory_collection.add(
            documents=[value],
            metadatas=[{"key": key, "date": str(datetime.now())}],
            ids=[doc_id]
        )
        return f"Remembered: {key}"
    except Exception as e:
        return f"Memory error: {e}"

def recall(query: str):
    if not memory_collection:
        return "Memory offline"
    try:
        results = memory_collection.query(query_texts=[query], n_results=3)
        if results["documents"] and results["documents"][0]:
            return "\n".join(results["documents"][0])
        return "No memories found"
    except Exception as e:
        return f"Recall error: {e}"

# --- AGENTIC LOOP ---
def agentic_reasoning(task: str, worker: str, payload: dict = None):
    
    # Memory worker
    if worker == "memory":
        if "remember" in task.lower():
            parts = task.lower().replace("remember", "").strip()
            return remember("user_memory", parts), "memory"
        else:
            return recall(task), "memory"
    
    # Hands worker (tools)
    if worker == "hands":
        if payload and "action" in payload:
            return system_tool(payload["action"]), "hands"
        return system_tool("whoami"), "hands"
    
    # Brain worker (LLM)
    if not ollama:
        return "Ollama not running. Start with: ollama serve", "error"
    
    # Get context from memory
    context = "No context"
    if memory_collection:
        try:
            results = memory_collection.query(query_texts=[task], n_results=2)
            if results["documents"] and results["documents"][0]:
                context = "\n".join(results["documents"][0])
        except:
            pass
    
    prompt = f"""You are REZ HIVE, a sovereign AI assistant.

MEMORY CONTEXT:
{context}

USER REQUEST:
{task}

If you need system info, say ACTION: <command>
Commands: cpu_usage, ram_usage, list_files, whoami, ipconfig, date, time

Otherwise respond helpfully."""

    # Try models
    models = ["phi3.5:3.8b", "phi3", "llama3.2", "mistral"]
    response_text = ""
    model_used = ""
    
    for model in models:
        try:
            resp = ollama.chat(model=model, messages=[
                {"role": "system", "content": "You are a helpful AI assistant."},
                {"role": "user", "content": prompt}
            ])
            response_text = resp["message"]["content"]
            model_used = model
            break
        except:
            continue
    
    if not response_text:
        return "No models available. Run: ollama pull phi3", "error"
    
    # Check for tool use
    if "ACTION:" in response_text:
        try:
            for line in response_text.split("\n"):
                if "ACTION:" in line:
                    action = line.split("ACTION:")[1].strip()
                    result = system_tool(action)
                    summary = ollama.chat(model=model_used, messages=[
                        {"role": "user", "content": f"Summarize this result: {result}"}
                    ])
                    return summary["message"]["content"], model_used
        except Exception as e:
            return f"Tool error: {e}", model_used
    
    # Save to memory
    if memory_collection:
        try:
            doc_id = f"chat_{int(time.time() * 1000)}"
            memory_collection.add(
                documents=[f"User: {task}\nAI: {response_text}"],
                metadatas=[{"source": "chat", "date": str(datetime.now())}],
                ids=[doc_id]
            )
        except:
            pass
    
    return response_text, model_used

# --- ENDPOINTS ---
@app.post("/api/kernel", response_model=TaskResponse)
async def kernel_endpoint(req: TaskRequest):
    start = time.time()
    result, model = agentic_reasoning(req.task, req.worker, req.payload)
    latency = int((time.time() - start) * 1000)
    return TaskResponse(
        content=result,
        model=model,
        latency=f"{latency}ms",
        status="success"
    )

@app.get("/api/status")
async def status_endpoint():
    ollama_ok = False
    chroma_ok = False
    
    if ollama:
        try:
            ollama.list()
            ollama_ok = True
        except:
            pass
    
    if chroma_client:
        try:
            chroma_client.heartbeat()
            chroma_ok = True
        except:
            pass
    
    return {"ollama": ollama_ok, "chroma": chroma_ok, "kernel": True}

@app.get("/api/memory/stats")
async def memory_stats():
    if not memory_collection:
        return {"total_memories": 0, "status": "offline"}
    try:
        count = memory_collection.count()
        return {"total_memories": count, "status": "online"}
    except:
        return {"total_memories": 0, "status": "error"}

@app.get("/")
async def root():
    return {"message": "REZ HIVE Kernel is running", "docs": "/docs"}

if __name__ == "__main__":
    import uvicorn
    print("=" * 50)
    print("REZ HIVE Kernel Starting...")
    print("API: http://localhost:8001")
    print("Docs: http://localhost:8001/docs")
    print("=" * 50)
    uvicorn.run(app, host="0.0.0.0", port=8001)
'@

Set-Content -Path "backend\kernel.py" -Value $kernelContent -Encoding UTF8
Write-Host "   Done - kernel.py created" -ForegroundColor Green

# ============================================
# STEP 4: Update next.config.js
# ============================================
Write-Host "[4/5] Updating Next.js config..." -ForegroundColor Yellow

$nextConfigContent = @'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  async rewrites() {
    return [
      {
        source: '/api/kernel',
        destination: 'http://localhost:8001/api/kernel',
      },
      {
        source: '/api/status',
        destination: 'http://localhost:8001/api/status',
      },
      {
        source: '/api/memory/stats',
        destination: 'http://localhost:8001/api/memory/stats',
      },
    ]
  },
}

module.exports = nextConfig
'@

Set-Content -Path "next.config.js" -Value $nextConfigContent -Encoding UTF8
Write-Host "   Done - next.config.js updated" -ForegroundColor Green

# ============================================
# STEP 5: Create Launch Scripts
# ============================================
Write-Host "[5/5] Creating launch scripts..." -ForegroundColor Yellow

# Backend script
$backendScript = @'
Write-Host "Starting REZ HIVE Backend..." -ForegroundColor Cyan
Set-Location "D:\okiru-os\The Reztack OS"
python backend/kernel.py
'@
Set-Content -Path "start-backend.ps1" -Value $backendScript -Encoding UTF8

# Frontend script
$frontendScript = @'
Write-Host "Starting REZ HIVE Frontend..." -ForegroundColor Cyan
Set-Location "D:\okiru-os\The Reztack OS"
npm run dev
'@
Set-Content -Path "start-frontend.ps1" -Value $frontendScript -Encoding UTF8

# Full stack script
$fullStackScript = @'
Write-Host "Starting REZ HIVE Full Stack..." -ForegroundColor Cyan

$ProjectPath = "D:\okiru-os\The Reztack OS"
Set-Location $ProjectPath

Write-Host "[1/3] Checking Ollama..." -ForegroundColor Yellow
$ollamaRunning = Get-Process ollama -ErrorAction SilentlyContinue
if (-not $ollamaRunning) {
    Start-Process powershell -ArgumentList "-Command", "ollama serve"
    Start-Sleep -Seconds 3
}
Write-Host "   Ollama ready" -ForegroundColor Green

Write-Host "[2/3] Starting Backend..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$ProjectPath'; python backend/kernel.py"
Start-Sleep -Seconds 3
Write-Host "   Backend ready" -ForegroundColor Green

Write-Host "[3/3] Starting Frontend..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$ProjectPath'; npm run dev"
Write-Host "   Frontend ready" -ForegroundColor Green

Write-Host ""
Write-Host "======================================================" -ForegroundColor Green
Write-Host "   REZ HIVE IS RUNNING" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green
Write-Host "Frontend:  http://localhost:3000" -ForegroundColor Cyan
Write-Host "Backend:   http://localhost:8001" -ForegroundColor Cyan
Write-Host "API Docs:  http://localhost:8001/docs" -ForegroundColor Cyan
Write-Host ""
'@
Set-Content -Path "start-rez-hive.ps1" -Value $fullStackScript -Encoding UTF8

Write-Host "   Done - Launch scripts created" -ForegroundColor Green

# ============================================
# COMPLETE
# ============================================
Write-Host ""
Write-Host "======================================================" -ForegroundColor Green
Write-Host "   REZ HIVE BACKEND SETUP COMPLETE" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green
Write-Host ""
Write-Host "To start everything:" -ForegroundColor Cyan
Write-Host "   .\start-rez-hive.ps1" -ForegroundColor Yellow
Write-Host ""
Write-Host "Or start individually:" -ForegroundColor Cyan
Write-Host "   .\start-backend.ps1" -ForegroundColor White
Write-Host "   .\start-frontend.ps1" -ForegroundColor White
Write-Host ""